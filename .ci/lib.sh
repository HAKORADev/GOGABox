#!/usr/bin/env bash
# shellcheck shell=bash
# ============================================================================
# arsenal shared helpers - source this file, never execute it directly.
# Works identically on a developer machine and on GitHub Actions runners.
# ============================================================================
GDA_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
GDA_LOCK="$GDA_ROOT/config/environment.lock"
GDA_PROJECTS="$GDA_ROOT/config/projects.json"
# Cache dir override: set GDA_CACHE_DIR env or put it in .ci/local.env
if [ -f "$GDA_ROOT/.ci/local.env" ]; then
  # shellcheck disable=SC1091
  set -a; source "$GDA_ROOT/.ci/local.env"; set +a
fi
GDA_CACHE="${GDA_CACHE_DIR:-$GDA_ROOT/.cache}"
GDA_ENV_FILE="$GDA_CACHE/env.sh"

gda_log()  { printf '\033[1;36m[arsenal]\033[0m %s\n' "$*"; }
gda_warn() { printf '\033[1;33m[arsenal]\033[0m %s\n' "$*"; }
gda_die()  { printf '\033[1;31m[arsenal] ERROR:\033[0m %s\n' "$*" >&2; exit 1; }

# gda_lock <jq-path> -> value from environment.lock
gda_lock() { jq -r "$1" "$GDA_LOCK"; }

# gda_project <jq-path> [project-key] -> value from projects.json (uses GDA_PROJECT_KEY if unset)
gda_project() {
  local key="${2:-${GDA_PROJECT_KEY:-}}"
  [ -n "$key" ] || gda_die "project key not set (pass as 2nd arg or export GDA_PROJECT_KEY)"
  jq -r ".projects[\"$key\"] $1 // empty" "$GDA_PROJECTS"
}

# Ensure the toolchain env file exists and load it (JAVA_HOME, ANDROID_HOME, GODOT_BIN, PATH)
gda_load_env() {
  if [ ! -f "$GDA_ENV_FILE" ]; then
    gda_die "toolchain not bootstrapped yet. Run: ./tools/bootstrap.sh   (works the same locally and on CI)"
  fi
  # shellcheck disable=SC1090
  source "$GDA_ENV_FILE"
}

gda_http_download() { # url dest
  local url="$1" dest="$2" tries=0
  mkdir -p "$(dirname "$dest")"
  while [ $tries -lt 3 ]; do
    if curl -fSL --retry 2 --connect-timeout 20 -o "$dest.part" "$url"; then
      mv "$dest.part" "$dest"; return 0
    fi
    tries=$((tries+1)); gda_warn "download retry $tries for $url"; sleep 3
  done
  gda_die "download failed: $url"
}

gda_require_cmds() {
  local c missing=""
  for c in "$@"; do command -v "$c" >/dev/null 2>&1 || missing="$missing $c"; done
  [ -z "$missing" ] || gda_die "missing required commands:$missing (install them and re-run)"
}
