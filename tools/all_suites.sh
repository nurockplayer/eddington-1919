#!/bin/bash
# Every tests/test_*.gd on the current checkout, one at a time, with a per-suite cap.
# Prints one line per suite; exits 1 if any suite fails. Run from the repo root through orb-test --host.
godot --headless --path . --import >/dev/null 2>&1
export EDD_SETTINGS_PATH="$PWD/.godot/test-settings.cfg"
fail=0
for f in tests/test_*.gd; do
  n=$(basename "$f" .gd); t0=$(date +%s)
  out=$(perl -e 'alarm shift; exec @ARGV' 900 godot --headless --path . --script "res://$f" 2>&1); code=$?
  line=$(printf '%s\n' "$out" | grep -E '[0-9]+ (checks|passed|failures)|^PASS' | tail -1 | cut -c1-80)
  printf '%-34s exit=%-3s %4ss  %s\n' "$n" "$code" "$(( $(date +%s)-t0 ))" "$line"
  if [ "$code" != 0 ]; then fail=1; printf '%s\n' "$out" | grep -E 'FAIL|ERROR|SCRIPT ERROR' | head -8 | cut -c1-170; fi
done
rm -f "$EDD_SETTINGS_PATH"
echo "ALL DONE fail=$fail $(date '+%F %H:%M %Z')"
exit $fail
