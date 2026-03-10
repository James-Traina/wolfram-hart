#!/usr/bin/env bash
#
# wolfram-check.sh
#
# Reports the status of the Wolfram setup: binary location, version, local
# engine license, cloud access, and the active WOLFRAM_MODE setting. The
# output is a plain key-value listing designed for LLM consumption.
#
# Usage
#   wolfram-check.sh
#
# Exit Codes
#   0   Checks completed (one or both modes may still be unavailable).
#   1   wolframscript could not be found.

set -euo pipefail

# ---------------------------------------------------------------------------
# Locate wolframscript
# ---------------------------------------------------------------------------
source "$(dirname "${BASH_SOURCE[0]}")/_find-wolframscript.sh"

if [[ -z "$WOLFRAMSCRIPT" ]]; then
    cat <<'MISSING'
status: NOT_FOUND
mode_set: (unset)

wolframscript is not installed. Choose a setup path:

Option A — Local Engine (offline-capable, ~1 GB download):
  macOS:  brew install --cask wolfram-engine
  Linux:  https://www.wolfram.com/engine/ (download .deb / .rpm)
  Then:   wolframscript   # sign in once to activate the license

Option B — Cloud evaluation (no Engine download, needs internet):
  macOS:  brew install wolframscript
  Linux:  https://www.wolfram.com/wolframscript/ (download binary)
  Then:   wolframscript -authenticate
          export WOLFRAM_MODE=cloud   # add to ~/.zshrc or ~/.bashrc
MISSING
    exit 1
fi

readonly WOLFRAM_MODE="${WOLFRAM_MODE:-auto}"
echo "status: FOUND"
echo "path: $WOLFRAMSCRIPT"
echo "mode_set: $WOLFRAM_MODE"

# Strip trailing slash from TMPDIR: on macOS TMPDIR ends with '/', causing
# double-slash paths that BSD mktemp rejects on some systems.
_TMPDIR="${TMPDIR%/}"

# Temp files for stderr capture; cleaned up on any exit via trap.
LOCAL_STDERR_FILE=""
CLOUD_STDERR_FILE=""
trap 'rm -f "$LOCAL_STDERR_FILE" "$CLOUD_STDERR_FILE"' EXIT

# ---------------------------------------------------------------------------
# Portable timeout wrapper
# ---------------------------------------------------------------------------
TIMEOUT_CMD=""
if command -v gtimeout &>/dev/null; then
    TIMEOUT_CMD="gtimeout"
elif command -v timeout &>/dev/null; then
    TIMEOUT_CMD="timeout"
fi

run_with_timeout() {
    local secs="$1"; shift
    if [[ -n "$TIMEOUT_CMD" ]]; then
        "$TIMEOUT_CMD" "${secs}s" "$@"
    else
        "$@"
    fi
}

trim_first_line() {
    printf '%s' "$1" | head -1 | sed 's/^[[:space:]]*//;s/[[:space:]]*$//'
}

# ---------------------------------------------------------------------------
# Version
# ---------------------------------------------------------------------------
VERSION_EXIT=0
VERSION=$(run_with_timeout 15 "$WOLFRAMSCRIPT" -version 2>&1) || VERSION_EXIT=$?
if [[ $VERSION_EXIT -ne 0 ]]; then
    echo "version: UNKNOWN (wolframscript -version exited with code $VERSION_EXIT)"
else
    echo "version: $VERSION"
fi

# ---------------------------------------------------------------------------
# Local engine check
# ---------------------------------------------------------------------------
echo ""
echo "--- local ---"
LOCAL_STDERR_FILE="$(mktemp "${_TMPDIR:-/tmp}/wolfram_chk_local_XXXXXX")"
LOCAL_EXIT=0
LOCAL_RESULT=$(run_with_timeout 15 "$WOLFRAMSCRIPT" -code '2+2' 2>"$LOCAL_STDERR_FILE") || LOCAL_EXIT=$?
LOCAL_STDERR=$(<"$LOCAL_STDERR_FILE")
rm -f "$LOCAL_STDERR_FILE"
# Trim whitespace and check for exact "4" on the first line to avoid false
# positives from error messages that happen to contain the digit 4.
LOCAL_FIRST=$(trim_first_line "$LOCAL_RESULT")
if [[ "$LOCAL_FIRST" == "4" ]]; then
    echo "local_licensed: YES"
    echo "local_test: 2+2 = 4"
    DETAILS_EXIT=0
    DETAILS=$(run_with_timeout 15 "$WOLFRAMSCRIPT" -code \
        'StringJoin[ToString[$VersionNumber], " | ", $SystemID, " | ", ToString[$ProcessorCount], " cores"]' \
        2>&1) || DETAILS_EXIT=$?
    if [[ $DETAILS_EXIT -ne 0 ]]; then
        echo "engine: UNKNOWN (exited with code $DETAILS_EXIT)"
    else
        echo "engine: $DETAILS"
    fi
elif [[ $LOCAL_EXIT -eq 124 || $LOCAL_EXIT -eq 137 ]]; then
    echo "local_licensed: TIMEOUT"
    echo "local_hint: local check timed out after 15s; the kernel may be slow to start — retry or increase timeout"
else
    echo "local_licensed: POSSIBLY_NO"
    echo "local_test_output: $LOCAL_RESULT"
    if [[ -n "$LOCAL_STDERR" ]]; then
        echo "local_test_stderr: $LOCAL_STDERR"
    fi
    echo "local_hint: run 'wolframscript' interactively to complete activation"
fi

# ---------------------------------------------------------------------------
# Cloud check
# ---------------------------------------------------------------------------
echo ""
echo "--- cloud ---"
CLOUD_STDERR_FILE="$(mktemp "${_TMPDIR:-/tmp}/wolfram_chk_cloud_XXXXXX")"
CLOUD_EXIT=0
CLOUD_RESULT=$(run_with_timeout 30 "$WOLFRAMSCRIPT" -cloud -code '2+2' 2>"$CLOUD_STDERR_FILE") || CLOUD_EXIT=$?
CLOUD_STDERR=$(<"$CLOUD_STDERR_FILE")
rm -f "$CLOUD_STDERR_FILE"
CLOUD_FIRST=$(trim_first_line "$CLOUD_RESULT")
if [[ "$CLOUD_FIRST" == "4" ]]; then
    echo "cloud_available: YES"
    echo "cloud_test: 2+2 = 4"
elif [[ $CLOUD_EXIT -eq 124 || $CLOUD_EXIT -eq 137 ]]; then
    echo "cloud_available: TIMEOUT"
    echo "cloud_hint: cloud check timed out after 30s; check network connectivity and retry"
else
    echo "cloud_available: NO"
    echo "cloud_test_output: $CLOUD_RESULT"
    if [[ -n "$CLOUD_STDERR" ]]; then
        echo "cloud_test_stderr: $CLOUD_STDERR"
    fi
    echo "cloud_hint: run 'wolframscript -authenticate' to set up cloud access"
fi

# ---------------------------------------------------------------------------
# Setup recommendations
# ---------------------------------------------------------------------------
echo ""
echo "--- setup ---"
if [[ "$LOCAL_FIRST" == "4" && "$CLOUD_FIRST" == "4" ]]; then
    echo "recommended_mode: auto (both local and cloud are available)"
elif [[ "$LOCAL_FIRST" == "4" ]]; then
    echo "recommended_mode: local (Engine licensed; cloud not configured)"
elif [[ "$CLOUD_FIRST" == "4" ]]; then
    echo "recommended_mode: cloud"
    echo "recommended_action: add 'export WOLFRAM_MODE=cloud' to ~/.zshrc or ~/.bashrc"
else
    echo "recommended_mode: NONE — neither mode is working"
    echo ""
    echo "To fix local:  run 'wolframscript' interactively to activate the license"
    echo "To fix cloud:  run 'wolframscript -authenticate'"
    echo "               then add 'export WOLFRAM_MODE=cloud' to your shell profile"
fi
