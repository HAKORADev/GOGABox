#!/usr/bin/env bash
# ============================================================================
# Materialize a project's android/ build tree + addons/ from:
#   1. the pinned Godot android_source.zip (export templates)
#   2. the project's android-overlay/  (manifest, gradle tweaks, icons)
#   3. shared plugins/ (java source staged into the gradle source set)
#   4. per-project config (ads_config.json)
# Deterministic: wipes android/build every run. Fast (<5s, cached downloads).
# Usage: .ci/materialize-project.sh <project-key>
# ============================================================================
set -euo pipefail
. "$(dirname "$0")/lib.sh"

[ -f "$GDA_ENV_FILE" ] || gda_die "run ./tools/bootstrap.sh first"
# shellcheck disable=SC1090
source "$GDA_ENV_FILE"

KEY="${1:?usage: materialize-project.sh <project-key>}"
GDA_PROJECT_KEY="$KEY"
P_PATH="$(gda_project '.path' "$KEY")"
PROJ="$GDA_ROOT/$P_PATH"
[ -d "$PROJ" ] || gda_die "project dir not found: $PROJ"
[ -d "$PROJ/android-overlay" ] || gda_die "missing $PROJ/android-overlay/ (required: it customizes the android template)"

TEMPLATES_DIR_NAME="$(gda_lock '.godot.templates_dir_name')"
GODOT_DIR="$GDA_CACHE/godot"
TPL="$GODOT_DIR/templates/$TEMPLATES_DIR_NAME"
[ -f "$TPL/android_source.zip" ] || gda_die "android_source.zip missing - run ./tools/bootstrap.sh"

# ---------------------------------------------------------------- 1. fresh template
gda_log "materialize[$KEY]: extracting android template"
rm -rf "$PROJ/android/build"
mkdir -p "$PROJ/android"
# android_source.zip layout detection (zip root may contain 'build/' or be the build dir itself)
if unzip -l "$TPL/android_source.zip" | grep -qE '^\s+[0-9]+\s+[0-9-]+ [0-9:]+\s+build/'; then
  unzip -qo "$TPL/android_source.zip" -d "$PROJ/android"
else
  mkdir -p "$PROJ/android/build"
  unzip -qo "$TPL/android_source.zip" -d "$PROJ/android/build"
fi
[ -f "$PROJ/android/build/build.gradle" ] || gda_die "template extraction failed (no build.gradle)"
echo -n "$TEMPLATES_DIR_NAME" > "$PROJ/android/.build_version"

# ---------------------------------------------------------------- 2. project overlay
gda_log "materialize[$KEY]: applying android-overlay"
cp -a "$PROJ/android-overlay/." "$PROJ/android/build/"

# ---------------------------------------------------------------- 3. shared plugins
mkdir -p "$PROJ/addons"
# GDA_FORCE_PLUGINS="a,b" overrides the registry's use_plugins (backend A/B
# testing without editing config; CI uses it to compile-verify every backend).
PLUGIN_LIST="$(gda_project '.use_plugins[]' "$KEY" 2>/dev/null || true)"
if [ -n "${GDA_FORCE_PLUGINS:-}" ]; then
  PLUGIN_LIST="${GDA_FORCE_PLUGINS//,/ }"
  gda_log "materialize[$KEY]: GDA_FORCE_PLUGINS override -> $PLUGIN_LIST"
fi
for plugin in $PLUGIN_LIST; do
  PDIR="$GDA_ROOT/plugins/$plugin"
  [ -d "$PDIR" ] || gda_die "plugin '$plugin' not found in plugins/"
  ADDON_DIR="$(jq -r '.addon_dir' "$PDIR/plugin.meta.json")"
  gda_log "materialize[$KEY]: staging plugin '$plugin' -> addons/$ADDON_DIR"
  rm -rf "$PROJ/addons/$ADDON_DIR"
  cp -a "$PDIR/addon" "$PROJ/addons/$ADDON_DIR"
  # plugin java sources -> AGP main source set (src/main/java, relative paths preserved)
  if [ -d "$PDIR/android" ]; then
    mkdir -p "$PROJ/android/build/src/main/java"
    cp -a "$PDIR/android/." "$PROJ/android/build/src/main/java/"
  fi
  # plugin gradle dependencies -> build.gradle (idempotent injection)
  for dep in $(jq -r '.gradle_deps[]?' "$PDIR/plugin.meta.json"); do
    if ! grep -q "$dep" "$PROJ/android/build/build.gradle"; then
      sed -i "s/^dependencies {/dependencies {\n    implementation \"$dep\"/" "$PROJ/android/build/build.gradle"
      gda_log "materialize[$KEY]: injected gradle dep: $dep"
    fi
  done
  # plugin manifest meta-data (v1 plugin registration) -> AndroidManifest.xml
  META_NAME="$(jq -r '.manifest_meta.name // empty' "$PDIR/plugin.meta.json")"
  if [ -n "$META_NAME" ]; then
    META_VALUE="$(jq -r '.manifest_meta.value' "$PDIR/plugin.meta.json")"
    MANIFEST="$PROJ/android/build/src/main/AndroidManifest.xml"
    [ -f "$MANIFEST" ] || gda_die "manifest not found: $MANIFEST"
    python3 "$GDA_ROOT/.ci/inject-manifest-meta.py" "$MANIFEST" "$META_NAME" "$META_VALUE"
  fi
  # autoload re-point (e.g. 'Ads' -> the staged backend's addon script)
  AUTOLOAD_NAME="$(jq -r '.autoload.name // empty' "$PDIR/plugin.meta.json")"
  AUTOLOAD_SCRIPT="$(jq -r '.autoload.script // empty' "$PDIR/plugin.meta.json")"
  if [ -n "$AUTOLOAD_NAME" ] && [ -n "$AUTOLOAD_SCRIPT" ]; then
    if grep -qE "^${AUTOLOAD_NAME}=" "$PROJ/project.godot"; then
      sed -i "s|^${AUTOLOAD_NAME}=\"\*.*\"|${AUTOLOAD_NAME}=\"*${AUTOLOAD_SCRIPT}\"|" "$PROJ/project.godot"
      gda_log "materialize[$KEY]: autoload '$AUTOLOAD_NAME' -> $AUTOLOAD_SCRIPT"
    else
      gda_die "project.godot has no autoload '$AUTOLOAD_NAME' (required by plugin '$plugin')"
    fi
  fi
  # per-project ads config injected into the addon (runtime reads res://addons/<dir>/ads_config.json)
  CFG_REL="$(gda_project '.ads_config' "$KEY")"
  if [ -n "$CFG_REL" ] && [ -f "$PROJ/$CFG_REL" ]; then
    cp "$PROJ/$CFG_REL" "$PROJ/addons/$ADDON_DIR/ads_config.json"
  fi
done

# ---------------------------------------------------------------- 4. gradle plumbing
gda_log "materialize[$KEY]: writing local.properties"
cat > "$PROJ/android/build/local.properties" <<EOF
sdk.dir=$ANDROID_HOME
EOF
[ -f "$PROJ/android/build/gradlew" ] && chmod +x "$PROJ/android/build/gradlew"

gda_log "materialize[$KEY]: OK"
