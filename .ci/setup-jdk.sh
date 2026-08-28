#!/usr/bin/env bash
# ============================================================================
# Setup JDK (Temurin 17) - idempotent. Resolves in this order:
#   1. $GDA_JDK_HOME explicitly set
#   2. previously installed into $GDA_CACHE/jdk
#   3. an existing JDK 17 on the machine (JAVA_HOME or /home/*/jdk-17*)
#   4. download the pinned Temurin tarball from environment.lock
# Usage: .ci/setup-jdk.sh    (idempotent; prints JAVA_HOME when done)
# ============================================================================
set -euo pipefail
. "$(dirname "$0")/lib.sh"

gda_require_cmds curl tar
JDK_DIR="$GDA_CACHE/jdk"
mkdir -p "$JDK_DIR"

resolve_existing() { # prints path if a JDK17 is usable
  local cand
  for cand in "${GDA_JDK_HOME:-}" "${JAVA_HOME:-}" "$JDK_DIR"/* "$HOME"/jdk-17* /home/z/jdk-17*; do
    [ -n "$cand" ] || continue
    [ -x "$cand/bin/java" ] || continue
    if "$cand/bin/java" -version 2>&1 | grep -q 'version "17'; then
      echo "$cand"; return 0
    fi
  done
  return 1
}

if resolved="$(resolve_existing)"; then
  JAVA_HOME="$resolved"
  gda_log "JDK 17 found: $JAVA_HOME"
else
  url="$(gda_lock '.jdk.url')"
  tarball="$JDK_DIR/$(basename "${url//%2B/+}")"
  gda_log "Downloading pinned JDK 17 ..."
  gda_http_download "$url" "$tarball"
  gda_log "Extracting JDK ..."
  tar -xzf "$tarball" -C "$JDK_DIR"
  rm -f "$tarball"
  resolved="$(ls -d "$JDK_DIR"/jdk-17* | head -1)"
  [ -x "$resolved/bin/java" ] || gda_die "JDK extraction failed ($resolved)"
  JAVA_HOME="$resolved"
  gda_log "JDK 17 installed: $JAVA_HOME"
fi

mkdir -p "$GDA_CACHE"
cat > "$GDA_ENV_FILE.tmp" <<EOF
export JAVA_HOME="$JAVA_HOME"
EOF
# merge: keep other exports if env.sh already exists
if [ -f "$GDA_ENV_FILE" ]; then
  grep -v '^export JAVA_HOME=' "$GDA_ENV_FILE" >> "$GDA_ENV_FILE.tmp" || true
fi
mv "$GDA_ENV_FILE.tmp" "$GDA_ENV_FILE"
gda_log "setup-jdk: OK ($JAVA_HOME)"
