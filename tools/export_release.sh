#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

version=$(sed -n 's/^config\/version="\([^"]*\)"$/\1/p' project.godot)
[[ -n "$version" ]] || { echo 'Missing config/version in project.godot' >&2; exit 1; }
mkdir -p build
archive="build/Eddington1919-${version}-macOS.zip"
godot --headless --path . --export-release "macOS" "$archive"
python3 -I tools/release_zip.py list "$archive"

# Locate the separate PCK bundled inside the macOS app and parse its directory.
scratch=$(mktemp -d "$PWD/build/release-check.XXXXXX")
trap 'rm -rf "$scratch"' EXIT
python3 -I tools/release_zip.py extract-pck "$archive" "$scratch/release.pck"
godot --headless --path "$scratch" --script "$PWD/tools/check_release_pack.gd" -- "$scratch/release.pck"
echo "Release package checked: $archive"
