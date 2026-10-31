#!/usr/bin/env bash
# Fetch the CC0 sample libraries used by render_cambridge.sh (and record the
# commits they are pinned at). Idempotent: existing clones are reused.
# Everything lives in the approved KIOXIA cache; nothing is written into the
# repo, and no build tools are needed (tools/music/sfz_render.py reads SFZ).
#
# Usage: bash tools/music/setup_libs.sh
set -euo pipefail

CACHE=${EDD_SOUNDFONTS:-/Volumes/KIOXIA/eddington-1919-cache/soundfonts}
mkdir -p "$CACHE"

# VSCO 2 CE keeps the .sfz mappings on its SFZ branch (master is raw WAVs only).
VSCO_DIR=$CACHE/VSCO-2-CE
if [ ! -d "$VSCO_DIR/.git" ]; then
    echo "clone VSCO-2-CE (SFZ branch) -> $VSCO_DIR"
    git clone --depth 1 --branch SFZ https://github.com/sgossner/VSCO-2-CE.git "$VSCO_DIR"
elif [ ! -f "$VSCO_DIR/SViolinVib.sfz" ]; then
    echo "switch $VSCO_DIR to the SFZ branch"
    git -C "$VSCO_DIR" fetch --depth 1 origin SFZ:refs/remotes/origin/SFZ
    git -C "$VSCO_DIR" checkout -B SFZ origin/SFZ
else
    echo "reuse $VSCO_DIR"
fi

# VCSL likewise ships the .sfz mappings on its `sfz` branch.
VCSL_DIR=$CACHE/VCSL
if [ ! -d "$VCSL_DIR/.git" ]; then
    echo "clone VCSL (sfz branch) -> $VCSL_DIR"
    git clone --depth 1 --branch sfz https://github.com/sgossner/VCSL.git "$VCSL_DIR"
elif [ -z "$(find "$VCSL_DIR" -maxdepth 4 -name '*.sfz' -print -quit)" ]; then
    echo "switch $VCSL_DIR to the sfz branch"
    git -C "$VCSL_DIR" fetch --depth 1 origin sfz:refs/remotes/origin/sfz
    git -C "$VCSL_DIR" checkout -B sfz origin/sfz
else
    echo "reuse $VCSL_DIR"
fi

{
    echo "VSCO-2-CE $(git -C "$VSCO_DIR" rev-parse HEAD)"
    echo "VCSL $(git -C "$VCSL_DIR" rev-parse HEAD)"
} | tee "$CACHE/PINS.txt"
