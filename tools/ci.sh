#!/usr/bin/env bash
# ============================================================================
# GitHub Actions status from the terminal - no `gh` CLI needed.
#
# Usage:
#   tools/ci.sh            list the last runs (id, workflow, status, verdict)
#   tools/ci.sh watch      tail the newest run until it finishes (exit 0 = green)
#   tools/ci.sh watch <run-id>   tail a specific run
#
# Auth (optional): GITHUB_TOKEN env var, or a PAT in $HOME/.arsenal-gh-token.
# Public repos work read-only without a token (lower API rate limits).
# ============================================================================
set -euo pipefail

REPO="${GDA_REPO:-HAKORADev/godot-android-arsenal}"
API="https://api.github.com"

TOKEN="${GITHUB_TOKEN:-}"
if [ -z "$TOKEN" ] && [ -f "$HOME/.arsenal-gh-token" ]; then
  TOKEN="$(tr -d ' \n' < "$HOME/.arsenal-gh-token")"
fi
AUTH=()
[ -n "$TOKEN" ] && AUTH=(-H "Authorization: Bearer $TOKEN")

api() { curl -sf "${AUTH[@]}" -H "Accept: application/vnd.github+json" "$API/$1"; }
die() { echo "ci: $*" >&2; exit 1; }

command -v jq >/dev/null || die "jq is required (see docs/SETUP.md prerequisites)"

list_runs() {
  api "repos/$REPO/actions/runs?per_page=8" | jq -r '.workflow_runs[] |
    [.id, .name, .head_branch, .event, .status, (.conclusion // "-"),
     (.run_started_at // "-")] | @tsv' |
  awk -F'\t' 'BEGIN{ printf "%-12s %-14s %-6s %-9s %-11s %-9s %s\n",
      "RUN", "WORKFLOW", "BRANCH", "EVENT", "STATUS", "VERDICT", "STARTED" }
    { printf "%-12s %-14s %-6s %-9s %-11s %-9s %s\n", $1, $2, $3, $4, $5, $6, $7 }'
}

latest_run_id() {
  api "repos/$REPO/actions/runs?per_page=1" | jq -r '.workflow_runs[0].id'
}

watch_run() {
  local id="$1" i status conclusion
  for i in $(seq 1 150); do                       # 150 x 20s = 50 min ceiling
    read -r status conclusion < <(api "repos/$REPO/actions/runs/$id" |
      jq -r '[.status, (.conclusion // "-")] | @tsv') || die "API error for run $id"
    if [ "$status" = "completed" ]; then
      case "$conclusion" in
        success) echo "ci: run $id completed: SUCCESS"; exit 0 ;;
        *)       echo "ci: run $id completed: $conclusion"; exit 1 ;;
      esac
    fi
    printf "ci: run %s is %s (%s elapsed)...\n" "$id" "$status" "$((i * 20))s"
    sleep 20
  done
  die "timed out waiting for run $id"
}

case "${1:-list}" in
  list)  list_runs ;;
  watch)
    id="${2:-$(latest_run_id)}"
    [ -n "$id" ] && [ "$id" != "null" ] || die "no runs found for $REPO"
    watch_run "$id"
    ;;
  *) grep '^#' "$0" | head -9; exit 1 ;;
esac
