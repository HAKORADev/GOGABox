#!/usr/bin/env bash
# ============================================================================
# Headless integration tests for a project (same everywhere: local + CI).
# Convention: <project>/tests/flow_test.tscn exits 0 on success.
# Usage: tools/test.sh <project-key>
# ============================================================================
set -euo pipefail
. "$(dirname "$0")/../.ci/lib.sh"
gda_require_cmds jq
gda_load_env

KEY="${1:-}"
[ -n "$KEY" ] || { grep '^#' "$0" | head -6; exit 1; }
P_PATH="$(gda_project '.path' "$KEY")"
[ -n "$P_PATH" ] || gda_die "project '$KEY' not in config/projects.json"
PROJ="$GDA_ROOT/$P_PATH"
TEST_SCENE="$PROJ/tests/flow_test.tscn"
[ -f "$TEST_SCENE" ] || gda_die "no test scene at $TEST_SCENE (convention: tests/flow_test.tscn)"

bash "$GDA_ROOT/.ci/materialize-project.sh" "$KEY"
gda_log "test[$KEY]: importing project"
"$GODOT_BIN" --headless --path "$PROJ" --import >/dev/null 2>&1 || true
gda_log "test[$KEY]: running flow_test"
"$GODOT_BIN" --headless --path "$PROJ" res://tests/flow_test.tscn
