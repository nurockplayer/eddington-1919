#!/bin/bash
# Row 8 / Refs #382: run under orb-test --heavy --host.
set -euo pipefail
repo=$PWD
head=$(rtk git rev-parse HEAD)
base=3d392c2
out="/Volumes/KIOXIA/eddington-1919-cache/director/fix/darkroom-chart-label/$head"
available=$(df -k /Volumes/KIOXIA | awk 'NR==2 {print $4}')
if [ "$available" -lt 3145728 ]; then
  echo 'BLOCKED: KIOXIA has less than 3 GiB free'
  exit 1
fi
scratch=$(mktemp -d /private/tmp/darkroom-chart-XXXXXX)
cleanup() {
  if [ -e "$scratch/main/.git" ]; then
    rtk git -C "$repo" worktree remove --force "$scratch/main"
  fi
  python3 -c 'import shutil,sys; shutil.rmtree(sys.argv[1])' "$scratch"
}
trap cleanup EXIT
export EDD_SETTINGS_PATH="$scratch/settings.cfg"
mkdir -p "$out" "$scratch/fixed" "$scratch/before"
for script in scripts/chart.gd scripts/ui.gd tests/test_layout_bounds.gd; do
  godot --headless --path "$repo" --check-only --script "res://$script"
done
perl -e 'alarm shift; exec @ARGV' 150 godot --headless --path "$repo" --script res://tests/test_layout_bounds.gd -- --darkroom-chart-only > "$out/fixed-test.txt" 2>&1 || { cat "$out/fixed-test.txt"; exit 1; }
rtk git worktree add --detach "$scratch/main" "$base"
cp "$repo/tests/test_layout_bounds.gd" "$scratch/main/tests/test_layout_bounds.gd"
cp -cR "$repo/.godot" "$scratch/main/.godot"
godot --headless --path "$scratch/main" --import > "$scratch/import.txt" 2>&1
godot --headless --path "$scratch/main" --check-only --script res://tests/test_layout_bounds.gd
set +e
perl -e 'alarm shift; exec @ARGV' 150 godot --headless --path "$scratch/main" --script res://tests/test_layout_bounds.gd -- --darkroom-chart-only > "$out/main-test.txt" 2>&1
status=$?
set -e
[ "$status" -eq 1 ] || { echo "Expected main regression exit 1, got $status"; exit 1; }
perl -e 'alarm shift; exec @ARGV' 150 godot --path "$repo" --resolution 1280x720 --fixed-fps 60 --always-on-top --script res://tests/test_layout_bounds.gd -- --darkroom-chart-only "--capture-dir=$scratch/fixed" > "$scratch/fixed-capture.txt" 2>&1
set +e
perl -e 'alarm shift; exec @ARGV' 150 godot --path "$scratch/main" --resolution 1280x720 --fixed-fps 60 --always-on-top --script res://tests/test_layout_bounds.gd -- --darkroom-chart-only "--capture-dir=$scratch/before" > "$scratch/main-capture.txt" 2>&1
status=$?
set -e
[ "$status" -eq 1 ] || { echo "Expected main capture regression exit 1, got $status"; exit 1; }
for frame in "$scratch/fixed/"*.png; do
  name=$(basename "$frame")
  magick "$scratch/before/$name" "$frame" +append "$out/$name"
done
{
  echo "Row 8 / issue #382; main $base LEFT, fix $head RIGHT; 1280x720 each."
  echo 'Locales zh_TW/en/ja/ko; text default/maximum; results zero/left (1.30)/einstein (1.75)/3/limit (360 micrometer pixels).'
  tail -n 1 "$out/main-test.txt"
  tail -n 1 "$out/fixed-test.txt"
} > "$out/report.txt"
cat "$out/report.txt"
