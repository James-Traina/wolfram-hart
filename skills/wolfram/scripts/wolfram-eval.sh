#!/usr/bin/env bash
#
# wolfram-eval.sh
#
# Executes Wolfram Language code through a locally installed wolframscript binary.
# Designed to be called by Claude Code as the sole interface to the Wolfram Engine.
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
#   0   Success (result printed to stdout).
#   1   wolframscript could not be found on this system.
#   2   wolframscript returned a non-zero exit code with no usable output.
#   3   The computation exceeded the timeout.

set -euo pipefail

readonly CODE="${1:?Usage: wolfram-eval.sh <code> [timeout]}"
readonly TIMEOUT="${2:-30}"

# ---------------------------------------------------------------------------
# Locate wolframscript
# ---------------------------------------------------------------------------
# Search the PATH first, then fall back to well-known install locations on
# macOS (Homebrew ARM/Intel, system, and app-bundle paths) and Linux.
# ---------------------------------------------------------------------------
WOLFRAMSCRIPT=""
for candidate in \
    "$(command -v wolframscript 2>/dev/null || true)" \
    "/opt/homebrew/bin/wolframscript" \
    "/usr/local/bin/wolframscript" \
    "/usr/bin/wolframscript" \
    "/Applications/Wolfram Engine.app/Contents/MacOS/wolframscript" \
    "/Applications/Mathematica.app/Contents/MacOS/wolframscript" \
    "/snap/bin/wolframscript"; do
    if [[ -n "$candidate" && -x "$candidate" ]]; then
        WOLFRAMSCRIPT="$candidate"
        break
    fi
done

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
fi

# ---------------------------------------------------------------------------
# Execute
# ---------------------------------------------------------------------------
# -f   read code from file (avoids argument-length and quoting limits)
# -print   send the result of the final expression to stdout
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
if [[ $EXIT_CODE -eq 124 ]]; then
    echo "TIMEOUT: computation exceeded the ${TIMEOUT}s limit."
    echo "Increase the timeout or simplify the expression."
    exit 3
fi

if [[ $EXIT_CODE -ne 0 && -z "$RESULT" ]]; then
    echo "ERROR: wolframscript exited with code $EXIT_CODE"
    [[ -n "$STDERR_CONTENT" ]] && echo "STDERR: $STDERR_CONTENT"
    exit 2
fi

# ---------------------------------------------------------------------------
# Emit output
# ---------------------------------------------------------------------------
# Print the computation result, then any Wolfram warning messages that were
# written to stderr (e.g. Power::infy) separated by a marker line.
# ---------------------------------------------------------------------------
if [[ -n "$RESULT" ]]; then
    echo "$RESULT"
fi

if [[ -n "$STDERR_CONTENT" ]]; then
    echo "---WARNINGS---"
    echo "$STDERR_CONTENT"
fi

exit 0
