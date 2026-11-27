#!/usr/bin/env bash
# Plays pace scenarios into the iOS Simulator microphone and records what the
# app counted. Audio path: afplay -> BlackHole 2ch (virtual device) -> default
# input device -> iOS Simulator microphone.
# Deliberately NOT `set -e`: every step reports, so one failure still leaves a
# complete log to read.
set -u
BUNDLE="${BUNDLE_ID:-com.sesliTesbih.app}"
SCEN="${SCENARIOS:-normal fast veryfast slow eight noise fast33 veryfast33}"
REPS="${REPEATS:-2}"
OUT=ci_out
mkdir -p "$OUT"
log() { echo "[$(date +%H:%M:%S)] $*"; }

log "=================== 1. audio loopback ==================="
brew install --cask blackhole-2ch 2>&1 | tail -6
brew install switchaudio-osx 2>&1 | tail -2
sudo killall coreaudiod 2>/dev/null; sleep 8
system_profiler SPAudioDataType 2>&1 | head -40
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
open -a Simulator --args -CurrentDeviceUDID "$UDID" 2>&1 || true
sleep 5
xcrun simctl install "$UDID" build/ios/iphonesimulator/Runner.app 2>&1
xcrun simctl privacy "$UDID" grant microphone "$BUNDLE" 2>&1
xcrun simctl privacy "$UDID" grant all "$BUNDLE" 2>&1 | head -2

log "=================== 3. maestro ==================="
curl -Ls "https://get.maestro.mobile.dev" | bash 2>&1 | tail -3
export PATH="$PATH:$HOME/.maestro/bin"
maestro --version 2>&1 | tail -1

cat > "$OUT/open_counter.yaml" <<EOF
appId: $BUNDLE
---
- launchApp
- extendedWaitUntil:
    visible: "Subhanallah"
    timeout: 90000
- tapOn: "Subhanallah"
- extendedWaitUntil:
    visible: "OK|Allow.*"
    optional: true
    timeout: 8000
- tapOn:
    text: "OK|Allow.*"
    optional: true
- extendedWaitUntil:
    visible: "OK|Allow.*"
    optional: true
    timeout: 8000
- tapOn:
    text: "OK|Allow.*"
    optional: true
- extendedWaitUntil:
    visible: "Reset"
    timeout: 30000
EOF
cat > "$OUT/reset.yaml" <<EOF
appId: $BUNDLE
---
- tapOn: "Reset"
EOF

log "open the counter screen"
maestro --device "$UDID" test "$OUT/open_counter.yaml" 2>&1 | tail -25
xcrun simctl io "$UDID" screenshot "$OUT/counter.png" 2>&1 | tail -1

log "=================== 4. scenarios ==================="
printf "%-11s %-4s %-8s %-7s %-6s %-9s %s\n" scenario run counted expect stt restarts notes
for k in $(seq 1 "$REPS"); do
  for s in $SCEN; do
    case "$s" in eight) EXP=8;; noise) EXP=0;; fast33|veryfast33) EXP=33;; *) EXP=10;; esac
    maestro --device "$UDID" test "$OUT/reset.yaml" >/dev/null 2>&1
    sleep 2
    xcrun simctl spawn "$UDID" log stream --style compact --level debug \
      --predicate 'eventMessage CONTAINS "DIAG"' > "$OUT/raw_${s}_${k}.txt" 2>&1 &
    LP=$!
    sleep 2
    afplay "ci_audio/$s.wav" > "$OUT/afplay_${s}_${k}.txt" 2>&1
    sleep 10
    kill $LP 2>/dev/null; wait $LP 2>/dev/null
    f="$OUT/raw_${s}_${k}.txt"
    final=$(grep " count " "$f" | tail -1 | sed -E 's/.*→ ([0-9]+).*/\1/')
    final=${final:-0}
    stt=$(grep -c "count .* via stt" "$f")
    rst=$(grep -c " restart reason" "$f")
    errs=$(grep " error " "$f" | sed -E 's/.*DIAG [0-9]+ error //; s/ permanent.*//' | sort | uniq -c | tr -s ' ' | tr '\n' ';')
    ap=$(head -c 120 "$OUT/afplay_${s}_${k}.txt" | tr '\n' ' ')
    printf "%-11s %-4s %-8s %-7s %-6s %-9s %s %s\n" "$s" "$k" "$final" "$EXP" "$stt" "$rst" "$errs" "$ap"
  done
done

log "=================== 5. first raw log ==================="
f=$(ls "$OUT"/raw_*_1.txt 2>/dev/null | head -1)
[ -n "$f" ] && { echo "--- $f"; head -60 "$f" | cut -c1-220; }
xcrun simctl io "$UDID" screenshot "$OUT/final.png" 2>&1 | tail -1
log "done"
exit 0
