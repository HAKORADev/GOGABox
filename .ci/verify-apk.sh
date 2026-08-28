#!/usr/bin/env bash
# ============================================================================
# Sanity-check an exported APK: signature, badging (package/version/ABIs),
# size report. Fails loudly if the APK is broken or has the wrong ABI.
# Usage: .ci/verify-apk.sh <apk-path> <expected-abi> <project-key>
# ============================================================================
set -euo pipefail
. "$(dirname "$0")/lib.sh"
[ -f "$GDA_ENV_FILE" ] || gda_die "run ./tools/bootstrap.sh first"
# shellcheck disable=SC1090
source "$GDA_ENV_FILE"

APK="${1:?apk path}"; WANT_ABI="${2:?expected abi}"; KEY="${3:?project key}"
[ -f "$APK" ] || gda_die "APK not found: $APK"
BT="$(ls -d "$ANDROID_HOME"/build-tools/*/ | sort | tail -1)"
AAPT2="$BT/aapt2"; APKSIGNER="$BT/apksigner"
[ -x "$AAPT2" ] || gda_die "aapt2 not found at $BT"

gda_log "verify[$KEY]: $APK ($(du -h "$APK" | cut -f1))"
"$APKSIGNER" verify "$APK" >/dev/null || gda_die "signature verification FAILED for $APK"
gda_log "verify[$KEY]: signature OK"

BADGING="$("$AAPT2" dump badging "$APK")"
PKG="$(echo "$BADGING" | grep -oE "^package: name='[^']+' versionCode='[^']+' versionName='[^']+'" || true)"
NATIVE="$(echo "$BADGING" | grep -oE "^native-code: .*" || true)"
SDKV="$(echo "$BADGING" | grep -oE "^sdkVersion:'[^']+'" || true)"
TSKV="$(echo "$BADGING" | grep -oE "^targetSdkVersion:'[^']+'" || true)"
gda_log "verify[$KEY]: $PKG | $SDKV $TSKV"
gda_log "verify[$KEY]: $NATIVE"

echo "$NATIVE" | grep -q "$WANT_ABI" || gda_die "ABI mismatch: wanted $WANT_ABI, badging says: $NATIVE"

# machine-readable line for build summaries
echo "OK|$KEY|$WANT_ABI|$(basename "$APK")|$(stat -c%s "$APK")|$PKG|$NATIVE"
