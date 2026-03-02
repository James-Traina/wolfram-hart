#!/usr/bin/env bash
#
# wolfram-eval.sh
#
# Executes Wolfram Language code through a locally installed wolframscript binary.
# Designed to be called by Claude Code as the primary interface to the Wolfram Engine.
#
# The script writes incoming code to a temporary file before passing it to
# wolframscript. This sidesteps every shell-quoting issue that would otherwise
# arise from Wolfram's bracket-heavy syntax and derivative apostrophes.
#
# Usage
#   wolfram-eval.sh <code> [timeout_seconds]
#
# Arguments
#   code              Wolfram Language code to evaluate.
#   timeout_seconds   Maximum wall-clock time for the computation (default: 30).
#
# Exit Codes
#   0   Success (result printed to stdout). Also used when wolframscript exits
#       non-zero but still produces output — the partial result is printed and
#       a note is appended to the warnings section.
#   1   wolframscript could not be found on this system (or missing argument).
#   2   wolframscript returned a non-zero exit code with no usable output.
#   3   The computation exceeded the timeout.

set -euo pipefail

readonly CODE="${1:?Usage: wolfram-eval.sh <code> [timeout]}"
readonly TIMEOUT="${2:-30}"

# ---------------------------------------------------------------------------
# Locate wolframscript
# ---------------------------------------------------------------------------
source "$(dirname "${BASH_SOURCE[0]}")/_find-wolframscript.sh"

if [[ -z "$WOLFRAMSCRIPT" ]]; then
    cat <<'MISSING'
NOT_INSTALLED: wolframscript is not available on this system.

To install the free Wolfram Engine:
  macOS   — brew install --cask wolfram-engine
  Linux   — https://www.wolfram.com/engine/ (download .deb / .rpm)
  Docker  — docker run -it wolframresearch/wolframengine

After installation run "wolframscript" once to activate your license.
MISSING
    exit 1
fi

# ---------------------------------------------------------------------------
# Prepare a temporary file for the code
# ---------------------------------------------------------------------------
TMPFILE=$(mktemp "${TMPDIR:-/tmp}/wolfram_XXXXXX.wl")
STDERR_FILE=$(mktemp "${TMPDIR:-/tmp}/wolfram_err_XXXXXX.txt")
trap 'rm -f "$TMPFILE" "$STDERR_FILE"' EXIT

printf '%s\n' "$CODE" > "$TMPFILE"

# ---------------------------------------------------------------------------
# Determine available timeout command
# ---------------------------------------------------------------------------
# macOS does not ship GNU coreutils, so "timeout" is absent unless the user
# installed it via Homebrew (as "gtimeout"). We check for both.
# ---------------------------------------------------------------------------
TIMEOUT_CMD=""
if command -v gtimeout &>/dev/null; then
    TIMEOUT_CMD="gtimeout"
elif command -v timeout &>/dev/null; then
    TIMEOUT_CMD="timeout"
else
    echo "WARNING: neither 'timeout' nor 'gtimeout' found; computation will run without a time limit." >&2
fi

# ---------------------------------------------------------------------------
# Execute
# ---------------------------------------------------------------------------
# -f       read code from file (avoids argument-length and quoting limits)
# -print   required: tells wolframscript to print the final expression's
#          value to stdout (without it, -f produces no final expression value)
# ---------------------------------------------------------------------------
RESULT=""
EXIT_CODE=0

if [[ -n "$TIMEOUT_CMD" ]]; then
    RESULT=$("$TIMEOUT_CMD" "${TIMEOUT}s" "$WOLFRAMSCRIPT" -f "$TMPFILE" -print 2>"$STDERR_FILE") || EXIT_CODE=$?
else
    RESULT=$("$WOLFRAMSCRIPT" -f "$TMPFILE" -print 2>"$STDERR_FILE") || EXIT_CODE=$?
fi

STDERR_CONTENT=$(cat "$STDERR_FILE" 2>/dev/null || true)

# ---------------------------------------------------------------------------
# Interpret exit status
# ---------------------------------------------------------------------------
# Exit code 124 = GNU timeout sent SIGTERM; 137 = escalated to SIGKILL (128+9)
if [[ $EXIT_CODE -eq 124 || $EXIT_CODE -eq 137 ]]; then
    printf '%s\n' "TIMEOUT: computation exceeded the ${TIMEOUT}s limit."
    printf '%s\n' "Increase the timeout or simplify the expression."
    exit 3
fi

if [[ $EXIT_CODE -ne 0 && -z "$RESULT" ]]; then
    printf '%s\n' "ERROR: wolframscript exited with code $EXIT_CODE"
    if [[ -n "$STDERR_CONTENT" ]]; then
        printf '%s\n' "STDERR: $STDERR_CONTENT"
    fi
    exit 2
fi

# ---------------------------------------------------------------------------
# Emit output
# ---------------------------------------------------------------------------
# Print the computation result (using printf to avoid echo interpreting flags
# like -e or -n that can appear in Wolfram expressions), then any warning
# messages separated by a marker line.
# ---------------------------------------------------------------------------
if [[ -n "$RESULT" ]]; then
    printf '%s\n' "$RESULT"
fi

if [[ $EXIT_CODE -ne 0 ]]; then
    # wolframscript failed but produced partial output — surface the exit code
    STDERR_CONTENT="wolframscript exited with code $EXIT_CODE${STDERR_CONTENT:+; $STDERR_CONTENT}"
fi

if [[ -n "$STDERR_CONTENT" ]]; then
    printf '%s\n' "---WARNINGS---"
    printf '%s\n' "$STDERR_CONTENT"
fi

exit 0
