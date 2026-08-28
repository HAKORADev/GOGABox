#!/usr/bin/env bash
# ============================================================================
# Setup Android SDK (cmdline-tools + platform-tools + platform + build-tools)
# Idempotent. Reuses an existing valid SDK if ANDROID_SDK_ROOT points at one
# that satisfies environment.lock (symlinked into the cache).
# Usage: .ci/setup-android-sdk.sh    (requires setup-jdk.sh first)
# ============================================================================
set -euo pipefail
. "$(dirname "$0")/lib.sh"

gda_require_cmds curl unzip java
[ -f "$GDA_ENV_FILE" ] || gda_die "run .ci/setup-jdk.sh first"
# shellcheck disable=SC1090
source "$GDA_ENV_FILE"

SDK_DIR="$GDA_CACHE/android-sdk"
PLATFORM="$(gda_lock '.android.packages[1]' | cut -d';' -f2)"        # android-36
BUILD_TOOLS="$(gda_lock '.android.packages[2]' | cut -d';' -f2)"     # 36.1.0

sdk_ok() { # $1 = sdk root
  [ -d "$1/platforms/$PLATFORM" ] && [ -d "$1/build-tools/$BUILD_TOOLS" ] \
    && [ -d "$1/platform-tools" ] && [ -d "$1/licenses" ]
}

# Reuse a pre-existing SDK (developer machine) by symlinking it into the cache
if [ ! -d "$SDK_DIR/platforms" ] && [ -n "${ANDROID_SDK_ROOT:-}" ] && sdk_ok "$ANDROID_SDK_ROOT"; then
  ln -sfn "$ANDROID_SDK_ROOT" "$SDK_DIR"
  gda_log "Linked existing SDK $ANDROID_SDK_ROOT into cache"
fi

if sdk_ok "$SDK_DIR" || { [ -L "$SDK_DIR" ] && sdk_ok "$(readlink -f "$SDK_DIR")"; }; then
  gda_log "Android SDK already ready: $SDK_DIR"
else
  gda_log "Installing Android SDK into $SDK_DIR ..."
  mkdir -p "$SDK_DIR/cmdline-tools"
  zipf="$GDA_CACHE/cmdline-tools.zip"
  gda_http_download "$(gda_lock '.android.cmdline_tools_url')" "$zipf"
  unzip -qo "$zipf" -d "$SDK_DIR/cmdline-tools"
  rm -f "$zipf"
  # google ships it as cmdline-tools/bin -> we need cmdline-tools/latest/bin
  [ -d "$SDK_DIR/cmdline-tools/latest" ] || mv "$SDK_DIR/cmdline-tools/cmdline-tools" "$SDK_DIR/cmdline-tools/latest"

  SDKM="$SDK_DIR/cmdline-tools/latest/bin/sdkmanager"
  gda_log "Accepting licenses ..."
  yes | "$SDKM" --sdk_root="$SDK_DIR" --licenses >/dev/null 2>&1 || true
  gda_log "Installing packages: $(gda_lock '.android.packages[]' | tr '\n' ' ')"
  yes | "$SDKM" --sdk_root="$SDK_DIR" $(gda_lock '.android.packages[]' | tr '\n' ' ') >/dev/null
  sdk_ok "$SDK_DIR" || gda_die "SDK installation did not produce expected components"
  gda_log "Android SDK installed."
fi

cat > "$GDA_ENV_FILE.tmp" <<EOF
export ANDROID_HOME="$SDK_DIR"
export ANDROID_SDK_ROOT="$SDK_DIR"
EOF
if [ -f "$GDA_ENV_FILE" ]; then
  grep -vE '^export (ANDROID_HOME|ANDROID_SDK_ROOT)=' "$GDA_ENV_FILE" >> "$GDA_ENV_FILE.tmp" || true
fi
mv "$GDA_ENV_FILE.tmp" "$GDA_ENV_FILE"
gda_log "setup-android-sdk: OK ($SDK_DIR)"
