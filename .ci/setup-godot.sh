#!/usr/bin/env bash
# ============================================================================
# Setup Godot editor (headless-capable) + Android export templates.
# Idempotent. Selectively extracts ONLY the Android artifacts from the
# 1.3GB templates archive to save disk (~300MB instead of ~2.5GB).
# Usage: .ci/setup-godot.sh
# ============================================================================
set -euo pipefail
. "$(dirname "$0")/lib.sh"

gda_require_cmds curl unzip
GODOT_DIR="$GDA_CACHE/godot"
GODOT_BIN="$GODOT_DIR/bin/godot"
TEMPLATES_DIR_NAME="$(gda_lock '.godot.templates_dir_name')"
# Keep templates inside our cache; Godot looks in ~/.local/share/godot/export_templates
USER_TEMPLATES="${HOME}/.local/share/godot/export_templates"
mkdir -p "$(dirname "$USER_TEMPLATES")" "$GODOT_DIR/bin"
ln -sfn "$GODOT_DIR/templates" "$USER_TEMPLATES"

version_ok() { [ -x "$1" ] && "$1" --version 2>/dev/null | grep -q "$(gda_lock '.godot.version')"; }

if version_ok "$GODOT_BIN"; then
  gda_log "Godot editor already ready: $GODOT_BIN ($($GODOT_BIN --version))"
else
  gda_log "Downloading Godot $(gda_lock '.godot.version') editor ..."
  zipf="$GODOT_DIR/editor.zip"
  gda_http_download "$(gda_lock '.godot.editor_url')" "$zipf"
  unzip -qo "$zipf" -d "$GODOT_DIR/extract"
  rm -f "$zipf"
  binf="$(find "$GODOT_DIR/extract" -name 'Godot_*linux.x86_64*' -type f | head -1)"
  [ -n "$binf" ] || gda_die "godot binary not found in editor zip"
  mv "$binf" "$GODOT_BIN" && chmod +x "$GODOT_BIN"
  rm -rf "$GODOT_DIR/extract"
  gda_log "Godot editor installed: $($GODOT_BIN --version)"
fi

if [ -f "$GODOT_DIR/templates/$TEMPLATES_DIR_NAME/android_source.zip" ]; then
  gda_log "Export templates (Android) already ready"
else
  gda_log "Downloading export templates (1.3GB - one time) ..."
  tpz="$GODOT_DIR/templates.tpz"
  gda_http_download "$(gda_lock '.godot.templates_url')" "$tpz"
  mkdir -p "$GODOT_DIR/templates/$TEMPLATES_DIR_NAME"
  # selective extraction: android artifacts only (tpz root is templates/<file>)
  unzip -qo "$tpz" "templates/android_source.zip" \
                    "templates/android_release.apk" \
                    "templates/android_debug.apk" \
                    -d "$GODOT_DIR/tmpex"
  mv "$GODOT_DIR/tmpex/templates/"* "$GODOT_DIR/templates/$TEMPLATES_DIR_NAME/"
  rm -rf "$GODOT_DIR/tmpex" "$tpz"
  gda_log "Export templates extracted (Android subset)."
fi

cat > "$GDA_ENV_FILE.tmp" <<EOF
export GODOT_BIN="$GODOT_BIN"
EOF
if [ -f "$GDA_ENV_FILE" ]; then
  grep -vE '^export GODOT_BIN=' "$GDA_ENV_FILE" >> "$GDA_ENV_FILE.tmp" || true
fi
mv "$GDA_ENV_FILE.tmp" "$GDA_ENV_FILE"
gda_log "setup-godot: OK"
