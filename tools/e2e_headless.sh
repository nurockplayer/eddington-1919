#!/usr/bin/env bash
# Headless end-to-end run of every autoplay route, one Godot at a time.
#
# Each route drives the real game through synthetic input on the headless display
# server and must reach the phase its windowed run reaches, with the same checks:
# evidence and score reported, stuck=0 for the 1919 routes, and the score cue
# contract. A missing phase (a timeout), a stuck walk or a failed cue check fails
# the route. Windowed runs (--always-on-top) are only for screenshots; see
# docs/PLAYTEST_BOT_DRIVE.md.
#
# Usage: orb-test --heavy --host -- ./tools/e2e_headless.sh
# (Owner rule 2026-10-25: tests never run bare on the host; orb-test holds the
# host-wide heavy lock, so this script takes no lock of its own.)
# Exits non-zero if any route fails.

set -u

GODOT=${GODOT:-godot}
FPS=60
tmp=$(mktemp -d "${TMPDIR:-/tmp}/e2e_headless.XXXXXX") || exit 1
trap 'rm -rf "$tmp"' EXIT

# route|cap_seconds|expected_terminal_phase|godot user args
# Prologue tidy/accuse end at PREP by contract (their 1919 receipt); honest runs
# the whole cross-era route to ENDING.
ROUTES=(
  "autoplay careful|120|ENDING|--autoplay=careful --seed=77"
  "autoplay rushed|120|ENDING|--autoplay=rushed --seed=515"
  "autoplay cherry|120|ENDING|--autoplay=cherry --seed=4242"
  "prologue honest|240|ENDING|--prologue-autoplay=honest --seed=77"
  "prologue tidy|180|PREP|--prologue-autoplay=tidy --seed=78"
  "prologue accuse|180|PREP|--prologue-autoplay=accuse --seed=79"
)

# A fresh checkout or worktree has no imported resources: every route would load
# null scenes and fail (or hang) for a reason unrelated to the game.
if [[ ! -d .godot/imported ]]; then
  echo "e2e: importing resources first (fresh checkout)"
  if ! perl -e 'alarm 600; exec @ARGV' "$GODOT" --headless --path . --import >"$tmp/import.log" 2>&1; then
    echo "e2e: import failed; see below" >&2
    tail -20 "$tmp/import.log" >&2
    exit 1
  fi
fi

failures=0
rows=()

for entry in "${ROUTES[@]}"; do
  IFS='|' read -r label cap expected user_args <<<"$entry"
  name=${label// /_}
  log="$tmp/$name.log"
  # The Mac has no `timeout`; perl's alarm caps a hung run. /usr/bin/time
  # measures the route itself.
  # shellcheck disable=SC2086
  /usr/bin/time -p perl -e "alarm $cap; exec @ARGV" \
    "$GODOT" --headless --path . --fixed-fps "$FPS" -- $user_args >"$log" 2>&1
  code=$?
  wall=$(sed -nE 's/^real ([0-9]+\.[0-9]+)$/\1/p' "$log" | tail -1)
  wall=${wall:-?}

  ending="-" evidence="-" score="-" stuck="-" cues="-" seed="-" phase="-" result_ok=0

  if [[ $label == autoplay* ]]; then
    line=$(grep -E '^\[BOT [a-z]+\] DONE ending=' "$log" | tail -1)
    if [[ -n $line ]]; then
      result_ok=1
      ending=$(sed -E 's/^.*DONE ending=(.*) evidence=(.*) score=(-?[0-9]+) stuck=([0-9]+) phase=([A-Z]+)$/\1/' <<<"$line")
      evidence=$(sed -E 's/^.*DONE ending=(.*) evidence=(.*) score=(-?[0-9]+) stuck=([0-9]+) phase=([A-Z]+)$/\2/' <<<"$line")
      score=$(sed -E 's/^.*DONE ending=(.*) evidence=(.*) score=(-?[0-9]+) stuck=([0-9]+) phase=([A-Z]+)$/\3/' <<<"$line")
      stuck=$(sed -E 's/^.*DONE ending=(.*) evidence=(.*) score=(-?[0-9]+) stuck=([0-9]+) phase=([A-Z]+)$/\4/' <<<"$line")
      phase=$(sed -E 's/^.*DONE ending=(.*) evidence=(.*) score=(-?[0-9]+) stuck=([0-9]+) phase=([A-Z]+)$/\5/' <<<"$line")
      seed=$(grep -E '^\[BOT [a-z]+\] seed [0-9]+$' "$log" | head -1 | awk '{print $NF}')
    fi
    # The careful bot is the one that runs the cue checks; it stops before the
    # result line when they fail. Rushed and cherry never checked them.
    if [[ $label == "autoplay careful" ]]; then
      if grep -qE '^\[BOT [a-z]+\] FAIL: ' "$log"; then cues="FAIL"; else cues="pass"; fi
    else
      cues="n/a"
    fi
  else
    scenario=${label#prologue }
    line=$(grep -E "^\[PROLOGUE $scenario\] (ENDING|PREP|INCOMPLETE) " "$log" | tail -1)
    if [[ -n $line ]]; then
      result_ok=1
      phase=$(sed -E 's/^\[PROLOGUE [a-z]+\] ([A-Z]+) .*/\1/' <<<"$line")
      ending=$phase
      seed=$(sed -E 's/^.* seed=(-?[0-9]+) .*/\1/' <<<"$line")
      evidence=$(sed -E 's/^.* evidence=([^ ]+) .*/\1/' <<<"$line")
      score=$(sed -E 's/^.* score=(-?[0-9]+) .*/\1/' <<<"$line")
      stuck="n/a"
      if [[ $scenario == honest ]]; then
        if grep -qE "^\[PROLOGUE honest\] score cue checks=\[\]" "$log"; then cues="pass"; else cues="FAIL"; fi
      else
        cues="n/a"
      fi
      grep -qE 'failures=\[\]$' <<<"$line" || result_ok=0
    fi
  fi

  ok=1
  (( code == 0 )) || ok=0
  (( result_ok == 1 )) || ok=0
  [[ $phase == "$expected" ]] || ok=0
  # A phase timeout still prints a result line further down; never accept it.
  grep -q 'TIMEOUT waiting for phase' "$log" && ok=0
  [[ $cues == FAIL ]] && ok=0
  [[ $stuck =~ ^[0-9]+$ ]] && (( stuck > 0 )) && ok=0
  if [[ $label == autoplay* ]]; then
    [[ $ending == "-" || -z $ending ]] && ok=0
    [[ $score =~ ^-?[0-9]+$ ]] && (( score >= 0 )) || ok=0
  fi
  if (( ok == 0 )); then
    failures=$((failures + 1))
    echo "route $label failed (exit $code, phase $phase, expected $expected):" >&2
    tail -n 15 "$log" >&2
  fi

  rows+=("$(printf '%-16s %-6s %-30s %-10s %-5s %-5s %-5s %7ss %3s' \
    "$label" "$seed" "$ending" "$evidence" "$score" "$stuck" "$cues" "$wall" "$code")")
done

printf '%-16s %-6s %-30s %-10s %-5s %-5s %-5s %8s %3s\n' \
  route seed ending evidence score stuck cues wall exit
printf '%-16s %-6s %-30s %-10s %-5s %-5s %-5s %8s %3s\n' \
  ---------------- ------ ------------------------------ ---------- ----- ----- ----- -------- ---
for row in "${rows[@]}"; do
  printf '%s\n' "$row"
done

if (( failures > 0 )); then
  echo "$failures route(s) failed" >&2
  exit 1
fi
echo "all ${#ROUTES[@]} routes passed"
