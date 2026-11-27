#!/usr/bin/env bash
# Android pace matrix: installs the BASE and NEW debug APKs alternately on the
# same emulator, plays the pace scenarios into its virtual microphone (emulator
# gRPC injectAudio) and records what the counter showed. Runs inside
# reactivecircus/android-emulator-runner (emulator already booted).
set -u
PKG=com.sesliTesbih.app
ACT=com.sesliTesbih.sesli_tesbih.MainActivity
OUT=ci_out
mkdir -p "$OUT/raw" "$OUT/screens"
ROUNDS="${ROUNDS:-2}"
PLAN="${PLAN:-normal:3 slow:2 fast:2 veryfast:2 eight:1 noise:1 fast33:1 ultrafast:1}"
VARIANTS="${VARIANTS:-base new}"
log() { echo "[$(date +%H:%M:%S)] $*"; }

log "device: $(adb shell getprop ro.product.model | tr -d '\r') android $(adb shell getprop ro.build.version.release | tr -d '\r')"
SZ=$(adb shell wm size | grep -oE '[0-9]+x[0-9]+' | tail -1)
W=${SZ%x*}; H=${SZ#*x}
log "screen $W x $H"
TAPX=$((W * 26 / 100)); TAPY=$((H * 29 / 100))
RSTX=$((W / 2));        RSTY=$((H * 879 / 1000))

{
  echo "== device";  adb shell getprop ro.product.model; adb shell getprop ro.build.version.release; adb shell getprop ro.build.version.sdk
  echo "== recognition services"; adb shell cmd package query-services -a android.speech.RecognitionService 2>&1 | grep -E "packageName=|name=" | sort -u
  echo "== default recogniser"; adb shell settings get secure voice_recognition_service
  echo "== google / speech packages"; adb shell pm list packages 2>/dev/null | grep -iE "google|speech|tts|\.as$"
  echo "== network"; adb shell dumpsys connectivity 2>/dev/null | grep -iE "Active default network|VALIDATED" | head -3
} > "$OUT/env.txt" 2>&1
cat "$OUT/env.txt"

adb shell settings put global hide_error_dialogs 1
adb shell svc power stayon true
adb shell input keyevent KEYCODE_WAKEUP
adb shell wm dismiss-keyguard >/dev/null 2>&1
echo "speech services:"; adb shell cmd package query-services -a android.speech.RecognitionService 2>&1 | grep -E "packageName=" | sort -u

AUDIO_MODE="${AUDIO_MODE:-auto}"   # grpc | host | auto (try grpc, fall back to host)
play() {  # scenario tag
  local s=$1 tag=$2
  if [ "$AUDIO_MODE" = host ]; then
    afplay "ci_audio/$s.wav" > "$OUT/raw/inj_$tag.txt" 2>&1
  else
    play "$s" "$tag"
  fi
}

# The on-device recogniser needs a language pack that Play services downloads
# AFTER first boot ("Failed to get language pack of required locale: error 13").
# Until it is there the app sees no locales and counts nothing. Re-open the
# counter every minute and look at the locale it picked.
wait_for_locale() {
  [ -f "$OUT/locale_ready" ] && return 0
  local i loc
  for i in $(seq 1 14); do
    adb shell am force-stop "$PKG"; adb logcat -c
    adb shell am start -n "$PKG/$ACT" >/dev/null 2>&1; sleep 22
    adb shell input tap "$TAPX" "$TAPY"; sleep 8
    loc=$(adb logcat -d 2>/dev/null | grep "flutter : DIAG" | grep -m1 "listen locale=" | sed -E 's/.*locale=//' | tr -d '')
    log "locale probe $i: '$loc'"
    echo "probe $i: locale='$loc'" >> "$OUT/locale_probe.txt"
    if [ -n "$loc" ]; then touch "$OUT/locale_ready"; return 0; fi
    sleep 40
  done
  log "no locale after the wait — continuing anyway"
}

open_counter() {
  adb shell am force-stop "$PKG"
  adb shell pm grant "$PKG" android.permission.RECORD_AUDIO
  adb shell am start -n "$PKG/$ACT" >/dev/null 2>&1
  sleep 25
  adb shell input tap "$TAPX" "$TAPY"
  sleep 12
}

run_one() {  # variant scenario round idx expected
  local v=$1 s=$2 r=$3 i=$4 exp=$5
  local tag="${v}_${s}_r${r}_${i}"
  adb shell input tap "$RSTX" "$RSTY"; sleep 3
  adb logcat -c
  python3 ci/android/inject.py "ci_audio/$s.wav" > "$OUT/raw/inj_$tag.txt" 2>&1
  sleep 9
  adb logcat -d 2>/dev/null | grep "flutter : DIAG" > "$OUT/raw/raw_$tag.txt"
  sed -E 's/^.*DIAG [0-9]+ //' "$OUT/raw/raw_$tag.txt" > "$OUT/raw/$tag.log"
  local f="$OUT/raw/$tag.log"
  local final stt rst wd errs lag
  final=$(grep "^count" "$f" | tail -1 | sed -E 's/.*→ ([0-9]+).*/\1/'); final=${final:-0}
  stt=$(grep -c "^count .* via stt" "$f")
  rst=$(grep -c "^restart reason" "$f")
  wd=$(grep -c "^watchdog" "$f")
  errs=$(grep "^error" "$f" | sed -E 's/error (error_)?//; s/ permanent.*//' | sort | uniq -c | tr -s ' ' | tr '\n' ';')
  lag=$(grep -o "late>100ms=[0-9]* max_lag=[0-9]*ms" "$OUT/raw/inj_$tag.txt")
  printf "%s,%s,%s,%s,%s,%s,%s,%s\n" "$v" "$s" "$r" "$i" "$final" "$exp" "$rst" "$wd" >> "$OUT/results.csv"
  printf "%-5s %-10s r%s#%s counted=%-3s expect=%-3s restarts=%-2s watchdog=%-2s %s %s\n" \
    "$v" "$s" "$r" "$i" "$final" "$exp" "$rst" "$wd" "$errs" "$lag"
}

echo "variant,scenario,round,idx,counted,expected,restarts,watchdog" > "$OUT/results.csv"
for r in $(seq 1 "$ROUNDS"); do
  for v in $VARIANTS; do
    log "=== round $r  variant $v ==="
    adb uninstall "$PKG" >/dev/null 2>&1
    adb install -r -g "$OUT/$v.apk" 2>&1 | tail -1
    open_counter
    wait_for_locale
    adb exec-out screencap -p > "$OUT/screens/${v}_r${r}_counter.png"
    for item in $PLAN; do
      s=${item%%:*}; n=${item##*:}
      case "$s" in eight) exp=8;; noise) exp=0;; fast33|veryfast33) exp=33;; *) exp=10;; esac
      for i in $(seq 1 "$n"); do
        run_one "$v" "$s" "$r" "$i" "$exp"
        # Sanity gate: if the very first run produced no recogniser result at
        # all, the environment has no working speech service — stop instead of
        # burning an hour on meaningless zeros.
        if [ ! -f "$OUT/sanity_done" ]; then
          if [ "$AUDIO_MODE" = auto ] && ! grep -q "^burst" "$OUT/raw/${v}_${s}_r${r}_${i}.log"; then
            log "no mic activity with gRPC injection — switching to host audio (afplay -> BlackHole)"
            AUDIO_MODE=host
            echo "audio mode: host (gRPC injection produced no mic activity)" >> "$OUT/env.txt"
            run_one "$v" "$s" "$r" "$i" "$exp"
          fi
          touch "$OUT/sanity_done"
          echo "audio mode used: $AUDIO_MODE" >> "$OUT/env.txt"
          if ! grep -q "^result" "$OUT/raw/${v}_${s}_r${r}_${i}.log"; then
            log "ABORT: no recogniser result in the first run — environment has no working speech recogniser"
            adb logcat -d 2>/dev/null | grep -iE "SpeechRecogni|RecognitionService|AiAi|speech|voice" | tail -60 > "$OUT/speech_logcat.txt"
            exit 0
          fi
        fi
      done
    done
  done
done

log "=== summary ==="
python3 - <<'PY'
import csv, collections
rows = list(csv.DictReader(open('ci_out/results.csv')))
g = collections.defaultdict(list)
for r in rows:
    g[(r['scenario'], r['variant'])].append((int(r['counted']), int(r['expected'])))
print(f"{'scenario':11s} {'variant':7s} {'runs':>4s} {'exact':>6s} {'under':>6s} {'over':>5s} {'mean/exp':>9s}  counts")
for (s, v), xs in sorted(g.items()):
    exact = sum(1 for c, e in xs if c == e)
    under = sum(1 for c, e in xs if c < e)
    over = sum(1 for c, e in xs if c > e)
    print(f"{s:11s} {v:7s} {len(xs):4d} {exact:6d} {under:6d} {over:5d} "
          f"{sum(c for c, _ in xs) / len(xs):5.1f}/{xs[0][1]:<3d}  {[c for c, _ in xs]}")
tot = collections.defaultdict(lambda: [0, 0, 0, 0])
for (s, v), xs in g.items():
    if s == 'noise':
        continue
    t = tot[v]
    for c, e in xs:
        t[0] += 1; t[1] += (c == e); t[2] += (c < e); t[3] += (c > e)
print()
for v, (n, ex, un, ov) in sorted(tot.items()):
    print(f"TOTAL {v}: {n} runs  exact {ex} ({100*ex/n:.0f}%)  under {un}  over {ov}")
PY
exit 0
