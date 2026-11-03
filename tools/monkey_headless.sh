#!/usr/bin/env bash
# Sequential random-input runs. Replay: ./tools/monkey_headless.sh 1 SEED 1919|prologue
# Usage: orb-test --host -- ./tools/monkey_headless.sh [count=12] [first_seed=1] [route=mixed]
set -u
GODOT=${GODOT:-godot}
count=${1:-12}
first=${2:-1}
route=${3:-mixed}
[[ $count =~ ^[1-9][0-9]*$ && $first =~ ^[0-9]+$ && $route =~ ^(mixed|1919|prologue)$ ]] || exit 2
count=$((10#$count))
first=$((10#$first))
mkdir -p .monkey-logs
scratch=$(mktemp -d "$PWD/.monkey-logs/settings.XXXXXX") || exit 1
# Preserve the real settings file even when the cap terminates Godot mid-menu.
app=$(sed -n 's/^config\/name="\(.*\)"$/\1/p' project.godot)
if [[ $(uname) == Darwin ]]; then
  settings="$HOME/Library/Application Support/Godot/app_userdata/$app/settings.cfg"
else
  settings="${XDG_DATA_HOME:-$HOME/.local/share}/godot/app_userdata/$app/settings.cfg"
fi
had_settings=0
if [[ -f $settings ]]; then cp "$settings" "$scratch/settings.cfg" || exit 1; had_settings=1; fi
restore() {
  if (( had_settings )); then cp "$scratch/settings.cfg" "$settings"; else rm -f "$settings"; fi
}
cleanup() {
  local code=$?
  if restore; then
    rm -rf "$scratch"
  else
    echo "settings restoration failed; backup retained at $scratch" >&2
    code=1
  fi
  exit "$code"
}
trap cleanup EXIT
trap 'exit 130' INT
trap 'exit 143' TERM
failures=0
printf '%-6s %-9s %-14s %-6s %-9s %s\n' seed route 'phase reached' stuck wall exit
for ((i=0; i<count; i++)); do
  seed=$((first+i))
  current=$route
  # Two 1919 runs per Cambridge run; the default is exactly eight plus four.
  if [[ $current == mixed ]]; then
    if (( i % 3 == 2 )); then current=prologue; else current=1919; fi
  fi
  cap=360
  flag=--autoplay=monkey
  if [[ $current == prologue ]]; then cap=540; flag=--prologue-autoplay=monkey; fi
  log=".monkey-logs/$current-$seed.log"
  restore || exit 1
  /usr/bin/time -p perl -e "alarm $cap; exec @ARGV" \
    "$GODOT" --headless --path . --fixed-fps 60 -- "$flag" "--seed=$seed" >"$log" 2>&1
  code=$?
  wall=$(sed -nE 's/^real ([0-9]+\.[0-9]+)$/\1/p' "$log" | tail -1)
  phase=$(sed -nE 's/^.*DONE .*phase=([A-Z]+).*$/\1/p' "$log" | tail -1)
  if [[ -z $phase ]]; then phase=$(sed -nE 's/^.* PHASE ([A-Z0-9_]+)$/\1/p' "$log" | tail -1); fi
  stuck=$(sed -nE 's/^.*DONE .*stuck=([0-9]+).*$/\1/p' "$log" | tail -1)
  ok=1
  [[ $code == 0 && $stuck == 0 ]] || ok=0
  if [[ $current == 1919 ]]; then [[ $phase == ENDING ]] || ok=0
  else [[ $phase == PREP || $phase == ENDING ]] || ok=0; fi
  if grep -qE 'SCRIPT ERROR|^ERROR:|TIMEOUT|STUCK|FAIL:' "$log"; then ok=0; fi
  printf '%-6s %-9s %-14s %-6s %-9s %s\n' "$seed" "$current" "${phase:--}" "${stuck:--}" "${wall:-?}s" "$code"
  if (( ! ok )); then
    failures=$((failures+1))
    echo "FAIL: replay ./tools/monkey_headless.sh 1 $seed $current; disruptions: $log" >&2
    grep -E 'SCRIPT ERROR|^ERROR:|TIMEOUT|STUCK|FAIL:|failures=|DISRUPT' "$log" | tail -12 >&2
  else
    rm -f "$log"
  fi
done
if (( failures )); then echo "$failures/$count monkey routes failed"; exit 1; fi
echo "all $count monkey routes passed"
