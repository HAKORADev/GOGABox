#!/usr/bin/env bash
# ============================================================================
# Compute the CI build matrix (also usable locally for dry-run planning).
#
# - workflow_dispatch: builds the requested project (+abi +build_type)
# - push:              builds every project with ci_auto=true, all ABIs
# Output: a single-line JSON for GitHub Actions `matrix: ${{ fromJson(...) }}`
# Usage: .ci/ci-matrix.sh [--event push|workflow_dispatch] [--project KEY]
#                         [--abi all|arm64-v8a|armeabi-v7a]
#                         [--build-type release|debug]
# ============================================================================
set -euo pipefail
. "$(dirname "$0")/lib.sh"

EVENT="push"; PROJECT=""; ABI="all"; BTYPE="release"
while [ $# -gt 0 ]; do
  case "$1" in
    --event) EVENT="$2"; shift 2 ;;
    --project) PROJECT="$2"; shift 2 ;;
    --abi) ABI="$2"; shift 2 ;;
    --build-type) BTYPE="$2"; shift 2 ;;
    *) gda_die "unknown arg: $1" ;;
  esac
done

if [ "$EVENT" = "workflow_dispatch" ]; then
  [ -n "$PROJECT" ] || gda_die "workflow_dispatch requires --project"
  keys="$PROJECT"
else
  keys="$(jq -r '.projects | to_entries[] | select(.value.enabled==true and .value.ci_auto==true) | .key' "$GDA_PROJECTS")"
  [ -n "$keys" ] || gda_die "no ci_auto projects found in config/projects.json"
fi

items=""
for key in $keys; do
  enabled="$(jq -r ".projects[\"$key\"].enabled // false" "$GDA_PROJECTS")"
  [ "$enabled" = "true" ] || gda_die "project '$key' is not enabled in config/projects.json"
  presets="$(jq -r ".projects[\"$key\"].abi_presets | keys[]" "$GDA_PROJECTS")"
  if [ "$ABI" = "all" ]; then
    abis="$presets"
  else
    echo "$presets" | grep -qx "$ABI" || gda_die "project '$key' has no ABI '$ABI' (has: $(echo $presets | tr '\n' ' '))"
    abis="$ABI"
  fi
  for a in $abis; do
    items="$items{\"project\":\"$key\",\"abi\":\"$a\",\"build_type\":\"$BTYPE\"},"
  done
done
[ -n "$items" ] || gda_die "empty build matrix"
echo "{\"include\":[${items%,}]}"
