#!/usr/bin/env bash
#
# wolfram-eval.sh
#
# Executes Wolfram Language code through a locally installed wolframscript
# binary, in local, cloud, or auto mode (default).
#
#   Local mode  — requires the Wolfram Engine installed and activated.
#   Cloud mode  — requires only the wolframscript binary and a Wolfram account.
#                 No Engine download needed. Set WOLFRAM_MODE=cloud to use it.
#
# Auto mode (default) tries local first and falls back to cloud if the local
# kernel is unavailable.
#
# Usage
#   wolfram-eval.sh <code> [timeout_seconds]
#
# Arguments
#   code              Wolfram Language code to evaluate.
#   timeout_seconds   Maximum wall-clock time for the computation (default: 30).
#
# Environment
#   WOLFRAM_MODE   auto (default) | local | cloud
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
readonly WOLFRAM_MODE="${WOLFRAM_MODE:-auto}"

# ---------------------------------------------------------------------------
# Locate wolframscript
# ---------------------------------------------------------------------------
source "$(dirname "${BASH_SOURCE[0]}")/_find-wolframscript.sh"

if [[ -z "$WOLFRAMSCRIPT" ]]; then
    cat <<'MISSING'
NOT_INSTALLED: wolframscript is not available on this system.

Choose a setup path:

Option A — Local Engine (offline-capable, ~1 GB download):
  macOS:  brew install --cask wolfram-engine
  Linux:  https://www.wolfram.com/engine/ (download .deb / .rpm)
  Then:   wolframscript   # sign in once to activate the license

Option B — Cloud evaluation (no Engine download, needs internet):
  macOS:  brew install wolframscript
  Linux:  https://www.wolfram.com/wolframscript/ (download binary)
  Then:   wolframscript -authenticate
          export WOLFRAM_MODE=cloud   # add to ~/.zshrc or ~/.bashrc

Run /wolfram-hart:check after setup to verify either option.
MISSING
    exit 1
fi

# ---------------------------------------------------------------------------
# Prepare a temporary file for the code
# ---------------------------------------------------------------------------
# On macOS, BSD mktemp only randomises trailing X's, so a template like
# "wolfram_XXXXXX.wl" (X's before ".wl") creates a literal file with that
# exact name every time — no randomisation. Moving X's to the end avoids this.
# Also strip the trailing "/" from TMPDIR (macOS always includes it) before
# concatenating so we don't produce a double-slash path.
_TMPDIR="${TMPDIR%/}"
TMPFILE=$(mktemp "${_TMPDIR:-/tmp}/wolfram_eval_XXXXXX")
STDERR_FILE=$(mktemp "${_TMPDIR:-/tmp}/wolfram_err_XXXXXX")
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

run_with_timeout() {
    local secs="$1"; shift
    if [[ -n "$TIMEOUT_CMD" ]]; then
        "$TIMEOUT_CMD" "${secs}s" "$@"
    else
        "$@"
    fi
}

# ---------------------------------------------------------------------------
# run_wolframscript <use_cloud>
#   use_cloud: "yes" to evaluate in the cloud, "no" for local.
#   Sets global RESULT, EXIT_CODE, STDERR_CONTENT.
# ---------------------------------------------------------------------------
run_wolframscript() {
    local use_cloud="$1"
    RESULT="" EXIT_CODE=0
    > "$STDERR_FILE"

    # Build argument list; -cloud must come before -f to be recognised.
    local ws_args
    if [[ "$use_cloud" == "yes" ]]; then
        ws_args=(-cloud -f "$TMPFILE" -print)
    else
        ws_args=(-f "$TMPFILE" -print)
    fi

    RESULT=$(run_with_timeout "$TIMEOUT" "$WOLFRAMSCRIPT" "${ws_args[@]}" 2>"$STDERR_FILE") || EXIT_CODE=$?

    STDERR_CONTENT=$(<"$STDERR_FILE")
}

# ---------------------------------------------------------------------------
# Execute
# ---------------------------------------------------------------------------
# -f       read code from file (avoids argument-length and quoting limits)
# -print   required: tells wolframscript to print the final expression's
#          value to stdout (without it, -f produces no final expression value)
# ---------------------------------------------------------------------------
RESULT="" EXIT_CODE=0 STDERR_CONTENT=""
BOTH_FAILED=0

case "$WOLFRAM_MODE" in
    cloud)
        run_wolframscript "yes"
        ;;
    local)
        run_wolframscript "no"
        ;;
    auto)
        run_wolframscript "no"
        # If local exited with an error and produced no output, try cloud.
        # Skip the fallback for timeouts (124 = SIGTERM, 137 = SIGKILL) —
        # those should surface as timeouts, not silently retry in the cloud.
        if [[ $EXIT_CODE -ne 0 && $EXIT_CODE -ne 124 && $EXIT_CODE -ne 137 && -z "$RESULT" ]]; then
            LOCAL_STDERR="$STDERR_CONTENT"
            run_wolframscript "yes"
            if [[ $EXIT_CODE -ne 0 && -z "$RESULT" ]]; then
                BOTH_FAILED=1
                # Preserve diagnostics from both attempts for the NOT_CONFIGURED path.
                STDERR_CONTENT="${LOCAL_STDERR}${STDERR_CONTENT:+; cloud: $STDERR_CONTENT}"
            elif [[ $EXIT_CODE -eq 0 || -n "$RESULT" ]]; then
                # Cloud succeeded as fallback — warn so user knows local is broken.
                STDERR_CONTENT="NOTE: local evaluation failed; fell back to cloud. Run /wolfram-hart:check to diagnose.${STDERR_CONTENT:+; $STDERR_CONTENT}"
            fi
        fi
        ;;
    *)
        printf '%s\n' "ERROR: unknown WOLFRAM_MODE '${WOLFRAM_MODE}' (expected: auto, local, or cloud)" >&2
        exit 1
        ;;
esac

# ---------------------------------------------------------------------------
# Interpret exit status
# ---------------------------------------------------------------------------
# Exit code 124 = GNU timeout sent SIGTERM; 137 = escalated to SIGKILL (128+9)
if [[ -n "$TIMEOUT_CMD" && ($EXIT_CODE -eq 124 || $EXIT_CODE -eq 137) ]]; then
    if [[ $BOTH_FAILED -eq 1 ]]; then
        printf '%s\n' "TIMEOUT: local evaluation failed, then cloud fallback timed out after ${TIMEOUT}s."
        printf '%s\n' "Run /wolfram-hart:check to diagnose the local setup; increase timeout or check network for cloud."
    else
        printf '%s\n' "TIMEOUT: computation exceeded the ${TIMEOUT}s limit."
        printf '%s\n' "Increase the timeout or simplify the expression."
    fi
    exit 3
fi

if [[ $EXIT_CODE -ne 0 && -z "$RESULT" ]]; then
    if [[ $BOTH_FAILED -eq 1 ]]; then
        cat <<'NOT_CONFIGURED'
NOT_CONFIGURED: wolframscript was found but neither local nor cloud evaluation worked.

To set up local evaluation:
  Run "wolframscript" interactively to complete license activation.

To set up cloud evaluation instead:
  Run "wolframscript -authenticate" then add to your shell profile:
    export WOLFRAM_MODE=cloud

Run /wolfram-hart:check to see the detailed status of each mode.
NOT_CONFIGURED
        if [[ -n "$STDERR_CONTENT" ]]; then
            printf '%s\n' "---DIAGNOSTICS---"
            printf '%s\n' "$STDERR_CONTENT"
        fi
    else
        printf '%s\n' "ERROR: wolframscript exited with code $EXIT_CODE"
        if [[ -n "$STDERR_CONTENT" ]]; then
            printf '%s\n' "STDERR: $STDERR_CONTENT"
        fi
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
