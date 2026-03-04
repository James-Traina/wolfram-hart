#!/usr/bin/env bash
# run-scorecard.sh — run the wolfram-hart 10-dimension plugin scorecard
#
# Usage:
#   bash tests/eval-framework/run-scorecard.sh

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
export REPO_ROOT

exec python3 "$REPO_ROOT/tests/eval-framework/score_plugin.py" "$REPO_ROOT"
