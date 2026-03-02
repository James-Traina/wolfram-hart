#!/usr/bin/env bash
#
# wolfram-check.sh
#
# Reports the status of the local Wolfram Engine installation: binary location,
# version string, license validity, and basic hardware info. The output is a
# plain key-value listing designed for LLM consumption.
#
# Usage
#   wolfram-check.sh
#
# Exit Codes
#   0   Installation found and checks completed.
#   1   wolframscript could not be found.

set -euo pipefail

# ---------------------------------------------------------------------------
# Locate wolframscript
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
status: NOT_FOUND

wolframscript is not installed.

Install the free Wolfram Engine:
  macOS   — brew install --cask wolfram-engine
  Linux   — https://www.wolfram.com/engine/ (download .deb / .rpm)
  Docker  — docker run -it wolframresearch/wolframengine

After installing, run "wolframscript" once to activate your license.
MISSING
    exit 1
fi

echo "status: FOUND"
echo "path: $WOLFRAMSCRIPT"

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
# License check (runs a trivial computation)
# ---------------------------------------------------------------------------
LICENSE_STDERR_FILE=$(mktemp "${TMPDIR:-/tmp}/wolfram_chk_XXXXXX.txt")
LICENSE_EXIT=0
RESULT=$(run_with_timeout 15 "$WOLFRAMSCRIPT" -code '2+2' 2>"$LICENSE_STDERR_FILE") || LICENSE_EXIT=$?
LICENSE_STDERR=$(cat "$LICENSE_STDERR_FILE" 2>/dev/null || true)
rm -f "$LICENSE_STDERR_FILE"
# Trim whitespace and check for exact "4" on the first line to avoid false
# positives from error messages that happen to contain the digit 4.
FIRST_LINE=$(printf '%s' "$RESULT" | head -1 | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
if [[ "$FIRST_LINE" == "4" ]]; then
    echo "licensed: YES"
    echo "test: 2+2 = 4"
else
    echo "licensed: POSSIBLY_NO"
    echo "test_output: $RESULT"
    if [[ -n "$LICENSE_STDERR" ]]; then
        echo "test_stderr: $LICENSE_STDERR"
    fi
    echo "hint: run 'wolframscript' interactively to complete license activation"
fi

# ---------------------------------------------------------------------------
# Engine details
# ---------------------------------------------------------------------------
DETAILS_EXIT=0
DETAILS=$(run_with_timeout 15 "$WOLFRAMSCRIPT" -code \
    'StringJoin[ToString[$VersionNumber], " | ", $SystemID, " | ", ToString[$ProcessorCount], " cores"]' \
    2>&1) || DETAILS_EXIT=$?
if [[ $DETAILS_EXIT -ne 0 ]]; then
    echo "engine: UNKNOWN (exited with code $DETAILS_EXIT)"
else
    echo "engine: $DETAILS"
fi
