#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

case "${1:-macos}" in
    macos) preset="macOS"; platform="macOS" ;;
    windows) preset="Windows Desktop"; platform="Windows" ;;
    linux) preset="Linux"; platform="Linux" ;;
    *) echo 'Usage: export_release.sh [macos|windows|linux]' >&2; exit 1 ;;
esac

version=$(sed -n 's/^config\/version="\([^"]*\)"$/\1/p' project.godot)
[[ -n "$version" ]] || { echo 'Missing config/version in project.godot' >&2; exit 1; }
mkdir -p build
archive="build/Eddington1919-${version}-${platform}.zip"
scratch=$(mktemp -d "$PWD/build/release-check.XXXXXX")
stage=
trap 'rm -rf "$scratch" ${stage:+"$stage"}' EXIT

if [[ "$platform" == Linux ]]; then
    # Godot names the binary after the export path, so export to a staging dir
    # and pack a stable Eddington1919.x86_64 + Eddington1919.pck by hand.
    stage=$(mktemp -d "$PWD/build/linux-stage.XXXXXX")
    godot --headless --path . --export-release "$preset" "$stage/Eddington1919.x86_64"
    rm -f "$archive"
    python3 -I tools/release_zip.py pack "$archive" "$stage/Eddington1919.x86_64" "$stage/Eddington1919.pck"
else
    godot --headless --path . --export-release "$preset" "$archive"
fi
python3 -I tools/release_zip.py list "$archive"

# Locate the separate PCK in the release ZIP and parse its directory.
python3 -I tools/release_zip.py extract-pck "$archive" "$scratch/release.pck"
godot --headless --path "$scratch" --script "$PWD/tools/check_release_pack.gd" -- "$scratch/release.pck"
echo "Release package checked: $archive"
