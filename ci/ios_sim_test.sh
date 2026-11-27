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
SCEN="${SCENARIOS:-normal fast veryfast slow eight noise fast33 veryfast33}"
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
xcrun simctl install "$UDID" build/ios/iphonesimulator/Runner.app 2>&1
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

log "=================== 3. one probe launch ==================="
PROBE="$OUT/probe.txt"
xcrun simctl spawn "$UDID" log stream --style compact --level debug \
  --predicate 'eventMessage CONTAINS "DIAG"' > "$PROBE" 2>&1 &
PLP=$!
sleep 2
xcrun simctl launch --terminate-running-process "$UDID" "$BUNDLE" 2>&1
for i in $(seq 1 24); do grep -q "DIAG [0-9]* status listening" "$PROBE" && break; sleep 2; done
sleep 3
xcrun simctl io "$UDID" screenshot "$OUT/probe_counter.png" 2>&1 | tail -1
kill $PLP 2>/dev/null; wait $PLP 2>/dev/null
echo "--- probe log:"; head -40 "$PROBE" | cut -c1-230

if ! grep -q "DIAG [0-9]* status listening" "$PROBE"; then
  log "listening was NOT reached — trying Maestro to dismiss a permission alert"
  curl -Ls "https://get.maestro.mobile.dev" | bash 2>&1 | tail -3
  export PATH="$PATH:$HOME/.maestro/bin"
  cat > "$OUT/dismiss.yaml" <<EOF
appId: $BUNDLE
---
- tapOn:
    text: "OK|Allow.*"
    optional: true
- tapOn:
    text: "OK|Allow.*"
    optional: true
EOF
  maestro --device "$UDID" test "$OUT/dismiss.yaml" 2>&1 | tail -20
  xcrun simctl io "$UDID" screenshot "$OUT/after_maestro.png" 2>&1 | tail -1
fi

log "=================== 4. scenarios ==================="
printf "%-11s %-4s %-8s %-7s %-6s %-9s %s\n" scenario run counted expect stt restarts notes
for k in $(seq 1 "$REPS"); do
  for s in $SCEN; do
    case "$s" in eight) EXP=8;; noise) EXP=0;; fast33|veryfast33) EXP=33;; *) EXP=10;; esac
    f="$OUT/raw_${s}_${k}.txt"
    xcrun simctl spawn "$UDID" log stream --style compact --level debug \
      --predicate 'eventMessage CONTAINS "DIAG"' > "$f" 2>&1 &
    LP=$!
    sleep 2
    xcrun simctl launch --terminate-running-process "$UDID" "$BUNDLE" > /dev/null 2>&1
    for i in $(seq 1 25); do grep -q "DIAG [0-9]* status listening" "$f" && break; sleep 2; done
    sleep 3
    afplay "ci_audio/$s.wav" > "$OUT/afplay_${s}_${k}.txt" 2>&1
    sleep 10
    kill $LP 2>/dev/null; wait $LP 2>/dev/null
    final=$(grep -E "DIAG [0-9]+ count " "$f" | tail -1 | sed -E 's/.*→ ([0-9]+).*/\1/')
    final=${final:-0}
    stt=$(grep -cE "DIAG [0-9]+ count .* via stt" "$f")
    rst=$(grep -cE "DIAG [0-9]+ restart reason" "$f")
    wd=$(grep -cE "DIAG [0-9]+ watchdog" "$f")
    lis=$(grep -cE "DIAG [0-9]+ status listening" "$f")
    errs=$(grep -E "DIAG [0-9]+ error " "$f" | sed -E 's/.*DIAG [0-9]+ error //; s/ permanent.*//' | sort | uniq -c | tr -s ' ' | tr '\n' ';')
    ap=$(head -c 100 "$OUT/afplay_${s}_${k}.txt" | tr '\n' ' ')
    printf "%-11s %-4s %-8s %-7s %-6s %-9s listening=%s wd=%s %s %s\n" "$s" "$k" "$final" "$EXP" "$stt" "$rst" "$lis" "$wd" "$errs" "$ap"
  done
done

log "=================== 5. first raw logs ==================="
for f in "$OUT"/raw_normal_1.txt "$OUT"/raw_fast_1.txt; do
  [ -f "$f" ] && { echo "--- $f"; head -50 "$f" | cut -c1-230; }
done
xcrun simctl io "$UDID" screenshot "$OUT/final.png" 2>&1 | tail -1
log "done"
exit 0
