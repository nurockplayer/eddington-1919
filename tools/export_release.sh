#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

version=$(sed -n 's/^config\/version="\([^"]*\)"$/\1/p' project.godot)
[[ -n "$version" ]] || { echo 'Missing config/version in project.godot' >&2; exit 1; }
mkdir -p build
archive="build/Eddington1919-${version}-macOS.zip"
godot --headless --path . --export-release "macOS" "$archive"
unzip -l "$archive"
entries=$(unzip -Z1 "$archive")
if grep -Eq '(^|/)(assets/licensed|tests)/' <<<"$entries"; then
  echo 'Forbidden licensed assets or tests in release ZIP' >&2
  exit 1
fi

# Inspect the pack in an empty resource root so checkout files cannot mask omissions.
scratch=$(mktemp -d "$PWD/build/release-check.XXXXXX")
trap 'rm -rf "$scratch"' EXIT
pack=$(grep -E '\.pck$' <<<"$entries")
[[ -n "$pack" && "$pack" != *$'\n'* ]] || { echo 'Expected one PCK in release ZIP' >&2; exit 1; }
unzip -p "$archive" "$pack" >"$scratch/release.pck"
godot --headless --path "$scratch" --script "$PWD/tools/check_release_pack.gd" -- "$scratch/release.pck"
echo "Release package checked: $archive"
