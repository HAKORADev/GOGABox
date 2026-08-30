#!/usr/bin/env bash
# ============================================================================
# Bootstrap the complete arsenal build environment. Idempotent - safe to
# re-run any time; skips whatever is already installed & valid.
#
# Installs: JDK 17 (Temurin) + Android SDK + Godot editor + export templates
#           + debug keystore. Writes the toolchain env into .cache/env.sh.
#
# Usage:  ./tools/bootstrap.sh            (same commands work on CI and local)
# ============================================================================
set -euo pipefail
. "$(dirname "$0")/../.ci/lib.sh"

gda_require_cmds jq curl unzip
mkdir -p "$GDA_CACHE"
gda_log "bootstrapping toolchain -> $GDA_CACHE"

bash "$GDA_ROOT/.ci/setup-jdk.sh"
bash "$GDA_ROOT/.ci/setup-android-sdk.sh"
bash "$GDA_ROOT/.ci/setup-godot.sh"

# --- debug keystore (generated once per machine; CI gets an ephemeral one) ---
# shellcheck disable=SC1090
source "$GDA_ENV_FILE"
KS="${GDA_DEBUG_KEYSTORE:-$HOME/.android/debug.keystore}"
if [ ! -f "$KS" ]; then
  mkdir -p "$(dirname "$KS")"
  gda_log "generating debug keystore: $KS"
  "$JAVA_HOME/bin/keytool" -genkeypair -keystore "$KS" \
    -storepass android -keypass android -alias androiddebugkey \
    -keyalg RSA -keysize 2048 -validity 10000 \
    -dname "CN=Android Debug,O=Android,C=US" >/dev/null 2>&1
fi

cat >> "$GDA_ENV_FILE" <<EOF
export GDA_DEBUG_KEYSTORE="$KS"
EOF

gda_log "toolchain ready:"
gda_log "  JAVA_HOME     = $JAVA_HOME"
gda_log "  ANDROID_HOME  = $ANDROID_HOME"
gda_log "  GODOT_BIN     = $GODOT_BIN"
gda_log "  keystore      = $KS"
gda_log "next: ./build.sh <project>   (e.g. ./build.sh gogabox)"
