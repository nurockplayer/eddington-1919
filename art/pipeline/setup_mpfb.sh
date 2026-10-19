#!/bin/sh
# Reproducible, isolated MPFB 2 setup for character builds (art/PIPELINE.md S3c).
#   art/pipeline/setup_mpfb.sh            # downloads, verifies, installs
#   eval "$(art/pipeline/setup_mpfb.sh --env)"   # exports BLENDER_USER_RESOURCES
#
# Nothing is installed into the user's own Blender profile: MPFB lives in an
# isolated BLENDER_USER_RESOURCES under ~/.cache/eddington-1919/mpfb.
#
# Sources and licences (checked 2026-10-20, see art/people/LICENSES.md):
#   MPFB 2.0.18, official Blender Extensions platform, GPL-3.0-or-later (tool only;
#     never shipped in the game). sha256 is part of the official download URL.
#   MakeHuman system assets pack (makehuman_system_assets_cc0.zip), official
#     MakeHuman community asset server, every asset listed as CC0.
set -eu
CACHE=${E1919_MPFB_CACHE:-$HOME/.cache/eddington-1919/mpfb}
export BLENDER_USER_RESOURCES="$CACHE/blender_user"
if [ "${1:-}" = "--env" ]; then echo "export BLENDER_USER_RESOURCES='$BLENDER_USER_RESOURCES'"; exit 0; fi

MPFB_SHA=c075b3e9b94b8e5556a5f03f4653602d02ea306de08126e8f55ed6dee28a2dad
MPFB_URL="https://extensions.blender.org/download/sha256:$MPFB_SHA/add-on-mpfb-v2.0.18.zip?repository=%2Fapi%2Fv1%2Fextensions%2F&blender_version_min=4.2.0"
SYS_SHA=b542127a8e25547c7c29c19f2d1d2adb9a664c80396ecd694095dbc8028a0107  # recorded 2026-10-20 (no official checksum published)
SYS_URL=https://files2.makehumancommunity.org/asset_packs/makehuman_system_assets/makehuman_system_assets_cc0.zip

mkdir -p "$CACHE/dl" "$BLENDER_USER_RESOURCES"
fetch() {  # url file sha
  [ -f "$CACHE/dl/$2" ] || curl -sSL -o "$CACHE/dl/$2" "$1"
  echo "$3  $CACHE/dl/$2" | shasum -a 256 -c - >/dev/null || { echo "checksum mismatch: $2" >&2; exit 1; }
}
fetch "$MPFB_URL" mpfb-2.0.18.zip "$MPFB_SHA"
fetch "$SYS_URL" makehuman_system_assets_cc0.zip "$SYS_SHA"
blender --command extension install-file -r user_default -e "$CACHE/dl/mpfb-2.0.18.zip" >/dev/null 2>&1
DATA="$BLENDER_USER_RESOURCES/extensions/.user/user_default/mpfb/data"
mkdir -p "$DATA"
# Staged extraction with a completion marker: an interrupted run never looks installed.
MARK="$DATA/.e1919_system_assets_$SYS_SHA"
if [ ! -f "$MARK" ]; then
  STAGE=$(mktemp -d "$CACHE/stage.XXXXXX")
  unzip -q "$CACHE/dl/makehuman_system_assets_cc0.zip" -d "$STAGE"
  for need in clothes/male_elegantsuit01 hair/short02 proxymeshes/male1591 eyes/low-poly eyebrows/eyebrow010; do
    [ -d "$STAGE/$need" ] || { echo "asset pack incomplete: $need" >&2; rm -rf "$STAGE"; exit 1; }
  done
  (cd "$STAGE" && tar cf - .) | (cd "$DATA" && tar xf -)
  rm -rf "$STAGE"
  touch "$MARK"
fi
echo "MPFB ready: BLENDER_USER_RESOURCES=$BLENDER_USER_RESOURCES"
