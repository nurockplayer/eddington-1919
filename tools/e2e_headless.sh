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
# Usage: orb-test --host -- ./tools/e2e_headless.sh
# (Owner rule 2026-10-25 JST: tests never run bare on the host; orb-test holds the
# host-wide test slot, so this script takes no lock of its own.)
# Exits non-zero if any route fails.

set -u

GODOT=${GODOT:-godot}
FPS=60
caps=$(perl -MPOSIX=ceil -e '
  $scale = shift;
  die "E2E_CAP_SCALE must be a positive number\n" unless $scale =~ /\A(?:\d+(?:\.\d*)?|\.\d+)(?:[eE][+-]?\d+)?\z/ && $scale > 0;
  print join " ", map { ceil($_ * $scale) } @ARGV;
' "${E2E_CAP_SCALE:-1}" 240 240 240 480 360 360) || exit 1
read -r careful_cap rushed_cap cherry_cap honest_cap tidy_cap accuse_cap <<<"$caps"
mkdir -p .godot
tmp=$(mktemp -d "$PWD/.godot/e2e_headless.XXXXXX") || exit 1
trap 'rm -rf "$tmp"' EXIT
export EDD_SETTINGS_PATH="${EDD_SETTINGS_PATH:-$tmp/settings.cfg}"

# E2E_PSEUDO=1 runs every route against a generated ASCII pseudo catalogue, so any
# CJK left on screen is a string L.t never saw. Each route must report
# `[LEAK] total 0`; a route without that line fails too.
pseudo=0
if [[ ${E2E_PSEUDO:-0} == 1 ]]; then
  pseudo=1
  if ! python3 -I tools/i18n.py pseudo "$tmp/pseudo.json" >"$tmp/pseudo.log" 2>&1; then
    echo "e2e: pseudo catalogue failed; see below" >&2
    cat "$tmp/pseudo.log" >&2
    exit 1
  fi
  export EDD_LOCALE=en
  export EDD_PSEUDO_JSON="$tmp/pseudo.json"
fi

# route|cap_seconds|expected_terminal_phase|godot user args
# Prologue tidy/accuse end at PREP by contract (their 1919 receipt); honest runs
# the whole cross-era route to ENDING. E2E_CAP_SCALE scales caps (default 1),
# rounding up to whole seconds.
ROUTES=(
  "autoplay careful|$careful_cap|ENDING|--autoplay=careful --seed=77"
  "autoplay rushed|$rushed_cap|ENDING|--autoplay=rushed --seed=515"
  "autoplay cherry|$cherry_cap|ENDING|--autoplay=cherry --seed=4242"
  "prologue honest|$honest_cap|ENDING|--prologue-autoplay=honest --seed=77"
  "prologue tidy|$tidy_cap|PREP|--prologue-autoplay=tidy --seed=78"
  "prologue accuse|$accuse_cap|PREP|--prologue-autoplay=accuse --seed=79"
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
  # Perl's alarm caps a hung run; Bash's time measures the route itself.
  # shellcheck disable=SC2086
  { time -p perl -e "alarm $cap; exec @ARGV" \
    "$GODOT" --headless --path . --fixed-fps "$FPS" -- $user_args; } >"$log" 2>&1
  code=$?
  wall=$(sed -nE 's/^real ([0-9]+\.[0-9]+)$/\1/p' "$log" | tail -1)
  wall=${wall:-?}

  ending="-" evidence="-" score="-" stuck="-" cues="-" seed="-" phase="-" leaks="-" result_ok=0

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
  if (( pseudo == 1 )); then
    leaks=$(grep -E '^\[LEAK\] total [0-9]+$' "$log" | tail -1 | awk '{print $NF}')
    if [[ ! $leaks =~ ^[0-9]+$ ]] || (( leaks > 0 )); then
      ok=0
    fi
  fi
  if [[ $label == autoplay* ]]; then
    [[ $ending == "-" || -z $ending ]] && ok=0
    [[ $score =~ ^-?[0-9]+$ ]] && (( score >= 0 )) || ok=0
  fi
  if (( ok == 0 )); then
    failures=$((failures + 1))
    echo "route $label failed (exit $code, phase $phase, expected $expected):" >&2
    tail -n 15 "$log" >&2
    if (( pseudo == 1 )) && [[ $leaks != 0 ]]; then
      echo "leaks in $label:" >&2
      grep '^\[LEAK\] ' "$log" | grep -v ' total ' | tail -n 20 >&2
    fi
  fi

  rows+=("$(printf '%-16s %-6s %-30s %-10s %-5s %-5s %-5s %-6s %7ss %3s' \
    "$label" "$seed" "$ending" "$evidence" "$score" "$stuck" "$cues" "$leaks" "$wall" "$code")")
done

# The routes never open the title, credits, settings, pause, help or log panels,
# and Chart's draw_string text is not a node property. The pseudo catalogue is
# already exported, so the suite walks those menus under the same locale. A
# skipped walk is a failure: it means the gate would pass without checking them.
if (( pseudo == 1 )); then
  log="$tmp/menu_leaks.log"
  perl -e 'alarm 300; exec @ARGV' \
    "$GODOT" --headless --path . --script res://tests/test_menu_leaks.gd >"$log" 2>&1
  code=$?
  if (( code != 0 )) || ! grep -qE '^\[LEAK\] total 0$' "$log" || grep -q 'menu walk skipped' "$log"; then
    failures=$((failures + 1))
    echo "menu walk failed (exit $code):" >&2
    grep '^\[LEAK\] ' "$log" | grep -v ' total ' | tail -n 20 >&2
    tail -n 15 "$log" >&2
  fi
fi

printf '%-16s %-6s %-30s %-10s %-5s %-5s %-5s %-6s %8s %3s\n' \
  route seed ending evidence score stuck cues leaks wall exit
printf '%-16s %-6s %-30s %-10s %-5s %-5s %-5s %-6s %8s %3s\n' \
  ---------------- ------ ------------------------------ ---------- ----- ----- ----- ------ -------- ---
for row in "${rows[@]}"; do
  printf '%s\n' "$row"
done

if (( failures > 0 )); then
  echo "$failures route(s) failed" >&2
  exit 1
fi
echo "all ${#ROUTES[@]} routes passed"
