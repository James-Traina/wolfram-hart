#!/usr/bin/env bash
#
# helpers.sh — assertion library and run_eval wrapper for wolfram-hart tests
#
# This file is SOURCED by run-all.sh, not executed directly.
#
# Globals set by run_eval:
#   LAST_STDOUT   captured stdout from wolfram-eval.sh
#   LAST_STDERR   captured stderr from wolfram-eval.sh
#   LAST_EXIT     exit code from wolfram-eval.sh
#
# Assertion return codes:
#   0  pass
#   1  fail
#   2  skip
#
# The _CURRENT_TEST_FAILED flag is set by any failing assertion. The runner
# checks this flag after each test function returns, so a test with multiple
# assertions correctly fails if ANY assertion fails (not just the last one).
#

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
EVAL_SCRIPT="$SCRIPT_DIR/../../skills/wolfram-hart/scripts/wolfram-eval.sh"
CHECK_SCRIPT="$SCRIPT_DIR/../../skills/wolfram-hart/scripts/wolfram-check.sh"

if [[ ! -f "$EVAL_SCRIPT" ]]; then
    echo "FATAL: wolfram-eval.sh not found at $EVAL_SCRIPT" >&2
    return 1
fi
if [[ ! -f "$CHECK_SCRIPT" ]]; then
    echo "FATAL: wolfram-check.sh not found at $CHECK_SCRIPT" >&2
    return 1
fi

# Globals set by run_eval
LAST_STDOUT=""
LAST_STDERR=""
LAST_EXIT=0

# Per-test failure tracking — set by _fail, checked by the runner
_CURRENT_TEST_FAILED=0

# Counters (managed by runner, but initialized here)
PASS_COUNT=${PASS_COUNT:-0}
FAIL_COUNT=${FAIL_COUNT:-0}
SKIP_COUNT=${SKIP_COUNT:-0}

# ---------------------------------------------------------------------------
# run_eval <code> [timeout]
# ---------------------------------------------------------------------------
# Calls wolfram-eval.sh, captures stdout, stderr, and exit code.
# ---------------------------------------------------------------------------
run_eval() {
    local code="$1"
    local timeout="${2:-30}"
    local tmp_out tmp_err

    tmp_out=$(mktemp "${TMPDIR:-/tmp}/test_out_XXXXXX")
    tmp_err=$(mktemp "${TMPDIR:-/tmp}/test_err_XXXXXX")

    LAST_EXIT=0
    LAST_STDOUT=$(bash "$EVAL_SCRIPT" "$code" "$timeout" 2>"$tmp_err") || LAST_EXIT=$?
    LAST_STDERR=$(<"$tmp_err")
    rm -f "$tmp_err"
}

# ---------------------------------------------------------------------------
# Assertions
# ---------------------------------------------------------------------------
# Every assertion prints PASS or FAIL and returns 0 or 1. On failure, the
# global _CURRENT_TEST_FAILED flag is also set so the runner can detect
# failures even when a later assertion in the same test passes.
# ---------------------------------------------------------------------------

_fail() {
    local msg="$1"
    echo "  FAIL: $msg"
    _CURRENT_TEST_FAILED=1
    return 1
}

_pass() {
    local msg="$1"
    echo "  PASS: $msg"
    return 0
}

assert_eq() {
    local actual="$1" expected="$2" msg="${3:-values should be equal}"
    if [[ "$actual" == "$expected" ]]; then
        _pass "$msg"
    else
        _fail "$msg (expected '$expected', got '$actual')"
    fi
}

assert_contains() {
    local haystack="$1" needle="$2" msg="${3:-should contain substring}"
    if [[ "$haystack" == *"$needle"* ]]; then
        _pass "$msg"
    else
        _fail "$msg (expected to contain '$needle' in '${haystack:0:200}')"
    fi
}

assert_not_contains() {
    local haystack="$1" needle="$2" msg="${3:-should not contain substring}"
    if [[ "$haystack" != *"$needle"* ]]; then
        _pass "$msg"
    else
        _fail "$msg (expected NOT to contain '$needle')"
    fi
}

assert_exit_code() {
    local expected="$1"
    shift
    local actual=0
    "$@" >/dev/null 2>&1 || actual=$?
    if [[ "$actual" -eq "$expected" ]]; then
        _pass "exit code $expected"
    else
        _fail "exit code (expected $expected, got $actual)"
    fi
}

assert_file_exists() {
    local path="$1" msg="${2:-file should exist}"
    if [[ -f "$path" ]]; then
        _pass "$msg"
    else
        _fail "$msg (file not found: $path)"
    fi
}

assert_file_size_gt() {
    local path="$1" min_bytes="$2" msg="${3:-file should be larger than $min_bytes bytes}"
    if [[ -f "$path" ]]; then
        local size
        # macOS stat uses -f%z, Linux uses -c%s
        size=$(stat -f%z "$path" 2>/dev/null || stat -c%s "$path" 2>/dev/null || echo 0)
        if [[ "$size" -gt "$min_bytes" ]]; then
            _pass "$msg (size: $size bytes)"
        else
            _fail "$msg (size: $size bytes, need > $min_bytes)"
        fi
    else
        _fail "$msg (file not found: $path)"
    fi
}

assert_numeric() {
    local value="$1" msg="${2:-should be numeric}"
    # Strip leading/trailing whitespace (printf avoids echo -n pitfalls)
    value=$(printf '%s' "$value" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
    if [[ "$value" =~ ^-?[0-9]*\.?[0-9]+([eE][-+]?[0-9]+)?$ ]]; then
        _pass "$msg"
    else
        _fail "$msg (not numeric: '$value')"
    fi
}

assert_match() {
    local value="$1" pattern="$2" msg="${3:-should match pattern}"
    if [[ "$value" =~ $pattern ]]; then
        _pass "$msg"
    else
        _fail "$msg (value '${value:0:200}' did not match pattern '$pattern')"
    fi
}

skip_test() {
    local msg="${1:-skipped}"
    echo "  SKIP: $msg"
    return 2
}
