#!/usr/bin/env bash
# Plays pace scenarios into the iOS Simulator microphone and records what the
# app counted. Audio path: afplay -> BlackHole 2ch (virtual device) -> default
# input device -> iOS Simulator microphone.
# The app is built with --dart-define=AUTO_OPEN_DHIKR=1 --dart-define=AUTO_RESET=1,
# so every launch opens the Subhanallah counter at 0 — no UI automation needed.
# Deliberately NOT `set -e`: every step reports, so one failure still leaves a
# complete log to read.
set -u
BUNDLE="${BUNDLE_ID:-com.sesliTesbih.app}"
SCEN="${SCENARIOS:-pause normal fast veryfast slow eight noise fast33 veryfast33}"
REPS="${REPEATS:-2}"
OUT=ci_out
mkdir -p "$OUT"
exec > >(tee "$OUT/full.log") 2>&1
log() { echo "[$(date +%H:%M:%S)] $*"; }

log "=================== 1. audio loopback ==================="
brew install --cask blackhole-2ch 2>&1 | tail -12
brew install switchaudio-osx 2>&1 | tail -3
sudo killall coreaudiod 2>/dev/null; sleep 8
system_profiler SPAudioDataType 2>&1 | head -50
SwitchAudioSource -a 2>&1
SwitchAudioSource -t input  -s "BlackHole 2ch" 2>&1
SwitchAudioSource -t output -s "BlackHole 2ch" 2>&1
echo "default input : $(SwitchAudioSource -c -t input 2>&1)"
echo "default output: $(SwitchAudioSource -c -t output 2>&1)"

log "=================== 2. simulator ==================="
UDID=$(xcrun simctl list devices available -j | python3 -c '
import json, sys
d = json.load(sys.stdin)["devices"]
c = [(r, x) for r, v in d.items() if "iOS" in r for x in v if x["name"].startswith("iPhone")]
c.sort(key=lambda t: (t[0], t[1]["name"]))
r, x = c[-1]
sys.stderr.write("using %s / %s\n" % (r, x["name"]))
print(x["udid"])')
echo "UDID=$UDID"
xcrun simctl boot "$UDID" 2>&1
xcrun simctl bootstatus "$UDID" -b 2>&1 | tail -2
xcrun simctl install "$UDID" ci_app/fixed.app 2>&1
xcrun simctl privacy "$UDID" grant microphone "$BUNDLE" 2>&1

# Speech-recognition permission cannot be granted with simctl: write it into the
# simulator's TCC database directly (best effort), then reboot the simulator.
log "TCC: grant microphone + speech recognition"
xcrun simctl shutdown "$UDID" 2>&1
TCC="$HOME/Library/Developer/CoreSimulator/Devices/$UDID/data/Library/TCC/TCC.db"
echo "TCC db: $TCC  exists=$([ -f "$TCC" ] && echo yes || echo no)"
if [ -f "$TCC" ]; then
  sqlite3 "$TCC" ".schema access" 2>&1 | head -5
  for svc in kTCCServiceMicrophone kTCCServiceSpeechRecognition; do
    sqlite3 "$TCC" "INSERT OR REPLACE INTO access (service, client, client_type, auth_value, auth_reason, auth_version, indirect_object_identifier, flags, last_modified) VALUES ('$svc','$BUNDLE',0,2,2,1,'UNUSED',0,CAST(strftime('%s','now') AS INTEGER));" 2>&1 | head -3
  done
  sqlite3 "$TCC" "SELECT service, client, auth_value FROM access;" 2>&1 | head
fi
xcrun simctl boot "$UDID" 2>&1
xcrun simctl bootstatus "$UDID" -b 2>&1 | tail -1
open -a Simulator --args -CurrentDeviceUDID "$UDID" 2>&1 || true
sleep 6

log "=================== 3. runs ==================="
# `log stream` into a file is block-buffered: killing it lost the last part of
# every run and made runs look like they counted nothing. `log show` reads the
# persisted log instead — no buffering.
capture() {  # $1 = output file: the DIAG lines of the LAST app launch
  xcrun simctl spawn "$UDID" log show --style compact --info --debug --last 5m \
    --predicate 'eventMessage CONTAINS "flutter: DIAG"' > "$1.all" 2>&1
  local n
  n=$(grep -n "DIAG [0-9]* init " "$1.all" | tail -1 | cut -d: -f1)
  if [ -n "$n" ]; then tail -n +"$n" "$1.all" > "$1"; else cp "$1.all" "$1"; fi
}

CUR_APP=""
run_one() {  # app tag scenario k
  local app=$1 tag=$2 s=$3 k=$4 EXP
  case "$s" in eight) EXP=8;; noise|silence60) EXP=0;; fast33|veryfast33) EXP=33;; *) EXP=10;; esac
  if [ "$CUR_APP" != "$app" ]; then
    xcrun simctl terminate "$UDID" "$BUNDLE" >/dev/null 2>&1
    xcrun simctl install "$UDID" "ci_app/$app.app" 2>&1 | tail -1
    CUR_APP=$app
  fi
  local f="$OUT/raw_${tag}_${s}_${k}.txt"
  xcrun simctl launch --terminate-running-process "$UDID" "$BUNDLE" > /dev/null 2>&1
  sleep 9
  if [ "$s" = "silence60" ]; then
    sleep 60
  else
    afplay "ci_audio/$s.wav" > "$OUT/afplay_${tag}_${s}_${k}.txt" 2>&1
    sleep 10
  fi
  capture "$f"
  local final stt rst wd lis errs
  final=$(grep -E "DIAG [0-9]+ count " "$f" | tail -1 | sed -E 's/.*→ ([0-9]+).*/\1/'); final=${final:-0}
  stt=$(grep -cE "DIAG [0-9]+ count .* via stt" "$f")
  rst=$(grep -cE "DIAG [0-9]+ restart reason" "$f")
  wd=$(grep -cE "DIAG [0-9]+ watchdog" "$f")
  lis=$(grep -cE "DIAG [0-9]+ status listening" "$f")
  errs=$(grep -E "DIAG [0-9]+ error " "$f" | sed -E 's/.*DIAG [0-9]+ error //; s/ permanent.*//' | sort | uniq -c | tr -s ' ' | tr '\n' ';')
  printf "%-7s %-11s #%s counted=%-3s expect=%-3s sessions=%-2s restarts=%-2s watchdog=%-2s %s\n" \
    "$tag" "$s" "$k" "$final" "$EXP" "$lis" "$rst" "$wd" "$errs"
  printf "%s,%s,%s,%s,%s,%s,%s,%s\n" "$tag" "$s" "$k" "$final" "$EXP" "$lis" "$rst" "$wd" >> "$OUT/results.csv"
}

echo "app,scenario,run,counted,expected,sessions,restarts,watchdog" > "$OUT/results.csv"

log "--- A. fixed app (cumulative tracker, watchdog, 150 ms restart, iOS pauseFor 55 s)"
for k in $(seq 1 "$REPS"); do
  for s in $SCEN; do run_one fixed fixed "$s" "$k"; done
done
run_one fixed fixed silence60 1

LEGACY_REPS="${LEGACY_REPS:-0}"
if [ "$LEGACY_REPS" -gt 0 ]; then
  log "--- B. legacy tracker (pre-1.5.5 rules) on the over-count scenarios"
  for k in $(seq 1 "$LEGACY_REPS"); do
    run_one legacy legacy pause "$k"
    run_one legacy legacy normal "$k"
  done
fi

log "=================== 4. summary ==================="
python3 - <<'PY'
import csv, collections
rows = list(csv.DictReader(open('ci_out/results.csv')))
g = collections.defaultdict(list)
for r in rows:
    g[(r['scenario'], r['app'])].append((int(r['counted']), int(r['expected']), int(r['sessions'])))
print(f"{'scenario':11s} {'app':7s} {'runs':>4s} {'exact':>5s} {'under':>5s} {'over':>4s}  counts (expected)  sessions")
for (s, a), xs in sorted(g.items()):
    ex = sum(c == e for c, e, _ in xs); un = sum(c < e for c, e, _ in xs); ov = sum(c > e for c, e, _ in xs)
    print(f"{s:11s} {a:7s} {len(xs):4d} {ex:5d} {un:5d} {ov:4d}  {[c for c,_,_ in xs]} ({xs[0][1]})  {[n for *_,n in xs]}")
PY

log "=================== 5. sample raw log ==================="
for f in "$OUT"/raw_fixed_pause_1.txt "$OUT"/raw_legacy_pause_1.txt; do
  [ -f "$f" ] && { echo "--- $f"; grep -E "DIAG [0-9]+ (count|status|restart |error|watchdog)" "$f" | sed -E 's/^.*flutter: DIAG [0-9]+ //' | head -45 | cut -c1-120; }
done
xcrun simctl io "$UDID" screenshot "$OUT/final.png" 2>&1 | tail -1
log "done"
exit 0
