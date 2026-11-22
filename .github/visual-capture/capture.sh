#!/bin/bash
# Runner side of .github/workflows/visual-capture.yml: renders the benchmark
# bookmarks of an imported checkout windowed on lavapipe (software Vulkan)
# under Xvfb, then writes manifest.jsonl. Not for the Mac: the host rules keep
# windowed Godot off it, and tools/ci_capture.sh dispatches this instead.
#
# Usage: capture.sh <game dir> <out dir>
set -euo pipefail
game=$(cd "$1" && pwd)
mkdir -p "$2"
out=$(cd "$2" && pwd)
here=$(cd "$(dirname "$0")" && pwd)

fail() { echo "::error::$*"; exit 1; }

case "${HEIGHT:-720}" in
  720) width=1280 ;;
  1080) width=1920 ;;
  1440) width=2560 ;;
  *) fail "height must be 720, 1080 or 1440, not '$HEIGHT'" ;;
esac
height=${HEIGHT:-720}
[[ $VIEWS =~ ^[a-z0-9_]+(,[a-z0-9_]+)*$ ]] || fail "views must be comma-separated bookmark names, not '$VIEWS'"
user_args=(--bench-cloud-t="$CLOUD_T" --seed=7)
[ -z "$STYLE_SET" ] || user_args+=(--style-set="$STYLE_SET")

# lavapipe is the only Vulkan driver on a hosted runner; pin it as package-smoke does.
for icd in lvp_icd.x86_64.json lvp_icd.json; do
  if [ -f "/usr/share/vulkan/icd.d/$icd" ]; then
    export VK_ICD_FILENAMES="/usr/share/vulkan/icd.d/$icd"
    break
  fi
done
[ -n "${VK_ICD_FILENAMES:-}" ] || fail "no lavapipe ICD in /usr/share/vulkan/icd.d"
echo "VK_ICD_FILENAMES=$VK_ICD_FILENAMES"

# One windowed Godot run of the game at the capture size. $1 is the log name,
# the rest are the arguments after the game's own ones.
render() {
  local log=$1; shift
  local status=0
  timeout --kill-after=30 "1500" \
    xvfb-run -a -s "-screen 0 ${width}x${height}x24" \
    godot --path "$game" --rendering-driver vulkan --audio-driver Dummy \
      --resolution "${width}x${height}" --fixed-fps 60 --always-on-top \
      --log-file "$out/$log" "$@" || status=$?
  if [ "$status" -eq 124 ] || [ "$status" -eq 137 ]; then fail "$log: Godot timed out"; fi
  if grep -nE 'SCRIPT ERROR|SHADER ERROR|STYLE ERROR|LOOK-SET ERROR' "$out/$log"; then
    fail "$log reports a script, shader or override error"
  fi
  [ "$status" -eq 0 ] || fail "$log: Godot exited $status"
}

date +%s.%N > "$out/.started"
render godot.log -- --benchmark="$out/frames" --bench-only="$VIEWS" "${user_args[@]}"
date +%s.%N > "$out/.finished"
grep -m1 -E 'Vulkan [0-9.]+ - Forward\+ - Using Device' "$out/godot.log" || fail "godot.log names no Vulkan Forward+ device"

python3 -I "$here/manifest.py" "$out" "$width" "$height"
