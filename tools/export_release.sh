#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

case "${1:-macos}" in
    macos) preset="macOS"; platform="macOS" ;;
    windows) preset="Windows Desktop"; platform="Windows" ;;
    *) echo 'Usage: export_release.sh [macos|windows]' >&2; exit 1 ;;
esac

version=$(sed -n 's/^config\/version="\([^"]*\)"$/\1/p' project.godot)
[[ -n "$version" ]] || { echo 'Missing config/version in project.godot' >&2; exit 1; }
mkdir -p build
archive="build/Eddington1919-${version}-${platform}.zip"
godot --headless --path . --export-release "$preset" "$archive"
python3 -I tools/release_zip.py list "$archive"

# Locate the separate PCK in the release ZIP and parse its directory.
scratch=$(mktemp -d "$PWD/build/release-check.XXXXXX")
trap 'rm -rf "$scratch"' EXIT
python3 -I tools/release_zip.py extract-pck "$archive" "$scratch/release.pck"
godot --headless --path "$scratch" --script "$PWD/tools/check_release_pack.gd" -- "$scratch/release.pck"
echo "Release package checked: $archive"
