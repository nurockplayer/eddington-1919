#!/bin/sh
set -eu
root="$(pwd)"
head_sha="$(rtk git rev-parse --short HEAD)"
out="/Volumes/KIOXIA/eddington-1919-cache/director/accept/459/$head_sha"
mkdir -p "$out"
export EDD_SETTINGS_PATH="$root/.godot/report-capture-settings.cfg"
godot --headless --path "$root" --check-only --script res://tools/layout_720p/report_capture.gd
godot --path "$root" --windowed --resolution 1280x720 --always-on-top --fixed-fps 60 --script res://tools/layout_720p/report_capture.gd -- "$out"
rm -f "$EDD_SETTINGS_PATH"
