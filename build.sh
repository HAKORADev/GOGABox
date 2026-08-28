#!/usr/bin/env bash
# ============================================================================
# arsenal main build CLI - source -> APK, identical locally and on CI.
#
# Usage:
#   ./build.sh <project-key> [--abi all|arm64-v8a|armeabi-v7a] [--type release|debug]
#              [--aab] [--skip-import]
#
# What it does:
#   1. materialize the project (android template + overlays + shared plugins)
#   2. patch export presets (version code/name, keystore, aab) from config
#   3. godot --headless --import
#   4. godot --headless --export-release per ABI (each export runs the full
#      gradle build -> real APK)
#   5. verify every APK (signature, badging, ABI, size) and write a summary
#
# Outputs land in  dist/<project>/<apk_name>-<abi>.apk
# ============================================================================
set -euo pipefail
. "$(dirname "$0")/.ci/lib.sh"

gda_require_cmds jq python3
gda_load_env

KEY=""; ABI="all"; BTYPE="release"; AAB=""; SKIP_IMPORT=""
while [ $# -gt 0 ]; do
  case "$1" in
    --abi) ABI="$2"; shift 2 ;;
    --type) BTYPE="$2"; shift 2 ;;
    --aab) AAB="1"; shift ;;
    --skip-import) SKIP_IMPORT="1"; shift ;;
    -*) gda_die "unknown flag: $1" ;;
    *) KEY="$1"; shift ;;
  esac
done
[ -n "$KEY" ] || { sed -n '2,12p' "$0"; exit 1; }
[ "$BTYPE" = "release" ] || [ "$BTYPE" = "debug" ] || gda_die "--type must be release|debug"

GDA_PROJECT_KEY="$KEY"
P_PATH="$(gda_project '.path' "$KEY")";  [ -n "$P_PATH" ] || gda_die "project '$KEY' not in config/projects.json"
PROJ="$GDA_ROOT/$P_PATH"
APK_NAME="$(gda_project '.apk_name' "$KEY")"
VNAME="$(gda_project '.version_name' "$KEY")"
VBASE="$(gda_project '.version_code_base' "$KEY")"
[ -z "$AAB" ] && AAB="$(gda_project '.aab' "$KEY")"

DIST="$GDA_ROOT/dist/$KEY"
mkdir -p "$DIST"

# ---------------------------------------------------------------- 1. materialize
bash "$GDA_ROOT/.ci/materialize-project.sh" "$KEY"

# ---------------------------------------------------------------- 2. patch presets
abi_code() {
  case "$1" in
    armeabi-v7a) echo $((VBASE + 1)) ;;
    arm64-v8a)   echo $((VBASE + 2)) ;;
    x86)         echo $((VBASE + 3)) ;;
    x86_64)      echo $((VBASE + 4)) ;;
    *) gda_die "unknown abi $1" ;;
  esac
}
# keystore: debug by default; set GDA_RELEASE_KEYSTORE/USER/PASS for prod signing
KS="${GDA_RELEASE_KEYSTORE:-$GDA_DEBUG_KEYSTORE}"
KU="${GDA_RELEASE_KEYSTORE_USER:-androiddebugkey}"
KP="${GDA_RELEASE_KEYSTORE_PASS:-android}"
FMT=0
if [ "$AAB" = "1" ] || [ "$AAB" = "true" ]; then FMT=1; fi

patch_preset() { # abi preset-name
  python3 "$GDA_ROOT/.ci/patch-preset.py" "$PROJ/export_presets.cfg" "$2" \
    "version/code=$(abi_code "$1")" \
    "version/name=\"$VNAME\"" \
    "application/export_format=$FMT" \
    "keystore/debug=\"$KS\"" "keystore/debug_user=\"$KU\"" "keystore/debug_password=\"$KP\"" \
    "keystore/release=\"$KS\"" "keystore/release_user=\"$KU\"" "keystore/release_password=\"$KP\""
}
for a in $(jq -r ".projects[\"$KEY\"].abi_presets | keys[]" "$GDA_PROJECTS"); do
  patch_preset "$a" "$(gda_project ".abi_presets[\"$a\"]" "$KEY")"
done

# ---------------------------------------------------------------- 3. import
if [ -z "$SKIP_IMPORT" ] || [ ! -d "$PROJ/.godot" ]; then
  gda_log "build[$KEY]: godot headless import"
  "$GODOT_BIN" --headless --path "$PROJ" --import 2>&1 | tail -3 || gda_die "godot import failed"
fi

# ---------------------------------------------------------------- 4. export per ABI
declare -a OUT_APKS=() OUT_ABIS=()
build_one() { # abi preset-name
  local a="$1" preset="$2"
  local ext="apk"; [ "$FMT" = "1" ] && ext="aab"
  local out="$DIST/${APK_NAME}-v${VNAME}-${a}.${ext}"
  gda_log "build[$KEY]: exporting $a ($preset) -> $(basename "$out")"
  local flag="--export-release"
  [ "$BTYPE" = "debug" ] && flag="--export-debug"
  "$GODOT_BIN" --headless --path "$PROJ" "$flag" "$preset" "$out" 2>&1 | tail -15
  [ -f "$out" ] || gda_die "export produced no file: $out"
  OUT_APKS+=("$out"); OUT_ABIS+=("$a")
}
if [ "$ABI" = "all" ]; then
  for a in $(jq -r ".projects[\"$KEY\"].abi_presets | keys[]" "$GDA_PROJECTS"); do
    build_one "$a" "$(gda_project ".abi_presets[\"$a\"]" "$KEY")"
  done
else
  PRESET="$(gda_project ".abi_presets[\"$ABI\"]" "$KEY")"
  [ -n "$PRESET" ] || gda_die "unknown ABI '$ABI' for $KEY"
  build_one "$ABI" "$PRESET"
fi

# ---------------------------------------------------------------- 5. verify + summary
SUMMARY="$DIST/BUILD_SUMMARY.md"
{
  echo "# Build summary - $KEY ($BTYPE)"
  echo ""
  echo "| artifact | abi | size |"
  echo "|---|---|---|"
} > "$SUMMARY"
for i in "${!OUT_APKS[@]}"; do
  bash "$GDA_ROOT/.ci/verify-apk.sh" "${OUT_APKS[$i]}" "${OUT_ABIS[$i]}" "$KEY" | sed 's/^/verify: /'
  echo "| $(basename "${OUT_APKS[$i]}") | ${OUT_ABIS[$i]} | $(du -h "${OUT_APKS[$i]}" | cut -f1) |" >> "$SUMMARY"
done
gda_log "build[$KEY]: SUCCESS"
cat "$SUMMARY"
