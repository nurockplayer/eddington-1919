#!/usr/bin/env bash
# Fetch the CC0 sample libraries used by render_cambridge.sh at the commits
# pinned below (the same commits docs/audio/SOURCES.md records) and write
# PINS.txt. Idempotent: existing clones at the pin are reused.
# Everything lives in the approved KIOXIA cache; nothing is written into the
# repo, and no build tools are needed (tools/music/sfz_render.py reads SFZ).
#
# Usage: bash tools/music/setup_libs.sh
set -euo pipefail

CACHE=${EDD_SOUNDFONTS:-/Volumes/KIOXIA/eddington-1919-cache/soundfonts}
mkdir -p "$CACHE"

# VSCO 2 CE keeps the .sfz mappings on its SFZ branch; VCSL on its sfz branch.
# A fresh clone has to ask for the commit itself: --branch would follow the
# moving branch tip instead of the pin.
VSCO_URL=https://github.com/sgossner/VSCO-2-CE.git
VSCO_PIN=6dd651d55dde97fd4028699be9d4481f26917891
VCSL_URL=https://github.com/sgossner/VCSL.git
VCSL_PIN=dfcf4a4918771eee884b96ad4493de82ef84daf6

# sync_lib <name> <dir> <url> <pin>
sync_lib() {
    local name=$1 dir=$2 url=$3 pin=$4
    if [ ! -d "$dir/.git" ]; then
        echo "clone $name at $pin -> $dir"
        git init -q "$dir"
        git -C "$dir" remote add origin "$url"
        git -C "$dir" fetch --depth 1 origin "$pin"
        git -C "$dir" checkout -q --detach FETCH_HEAD
    elif [ "$(git -C "$dir" rev-parse HEAD)" != "$pin" ]; then
        echo "update $dir to $pin"
        git -C "$dir" fetch --depth 1 origin "$pin" \
            || { echo "ERROR: cannot fetch $name pin $pin in $dir" >&2; exit 1; }
        git -C "$dir" checkout -q --detach FETCH_HEAD \
            || { echo "ERROR: cannot check out $name pin $pin in $dir" >&2; exit 1; }
    else
        echo "reuse $dir"
    fi
}

sync_lib VSCO-2-CE "$CACHE/VSCO-2-CE" "$VSCO_URL" "$VSCO_PIN"
sync_lib VCSL "$CACHE/VCSL" "$VCSL_URL" "$VCSL_PIN"

for pair in "VSCO-2-CE $VSCO_PIN" "VCSL $VCSL_PIN"; do
    set -- $pair
    head=$(git -C "$CACHE/$1" rev-parse HEAD)
    if [ "$head" != "$2" ]; then
        echo "ERROR: $1 is at $head, expected $2" >&2
        exit 1
    fi
done

{
    echo "VSCO-2-CE $(git -C "$CACHE/VSCO-2-CE" rev-parse HEAD)"
    echo "VCSL $(git -C "$CACHE/VCSL" rev-parse HEAD)"
} | tee "$CACHE/PINS.txt"
