#!/bin/sh
set -eu
baseline="$1"
root="$(pwd)"
scratch="$root/.godot/report-baseline-459"
accept="/Volumes/KIOXIA/eddington-1919-cache/director/accept/459"
fixed="$accept/8a84af2"
main="$accept/main-$(printf '%s' "$baseline" | cut -c1-7)"
mkdir -p "$fixed" "$main"
rtk git worktree add --detach "$scratch" "$baseline"
cleanup() {
  rtk git worktree remove --force "$scratch"
}
trap cleanup EXIT
cp "$root/tools/layout_720p/report_capture.gd" "$scratch/tools/layout_720p/report_capture.gd"
export EDD_SETTINGS_PATH="$root/.godot/report-capture-settings.cfg"
godot --headless --path "$scratch" --import
godot --headless --path "$scratch" --check-only --script res://tools/layout_720p/report_capture.gd
godot --headless --path "$root" --check-only --script res://tools/layout_720p/report_capture.gd
godot --path "$scratch" --windowed --resolution 1280x720 --always-on-top --fixed-fps 60 --script res://tools/layout_720p/report_capture.gd -- "$main" --baseline
godot --path "$root" --windowed --resolution 1280x720 --always-on-top --fixed-fps 60 --script res://tools/layout_720p/report_capture.gd -- "$fixed"
rm -f "$EDD_SETTINGS_PATH"
