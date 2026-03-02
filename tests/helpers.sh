#!/usr/bin/env bash
#
# helpers.sh — assertion library and run_eval wrapper for wolfram-skill tests
#

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
EVAL_SCRIPT="$SCRIPT_DIR/../skills/wolfram/scripts/wolfram-eval.sh"
CHECK_SCRIPT="$SCRIPT_DIR/../skills/wolfram/scripts/wolfram-check.sh"

# Globals set by run_eval
LAST_STDOUT=""
LAST_STDERR=""
LAST_EXIT=0

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
    bash "$EVAL_SCRIPT" "$code" "$timeout" >"$tmp_out" 2>"$tmp_err" || LAST_EXIT=$?

    LAST_STDOUT=$(cat "$tmp_out")
    LAST_STDERR=$(cat "$tmp_err")
    rm -f "$tmp_out" "$tmp_err"
}

# ---------------------------------------------------------------------------
# Assertions
# ---------------------------------------------------------------------------

_fail() {
    local msg="$1"
    echo "  FAIL: $msg"
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
    # Strip leading/trailing whitespace
    value=$(echo "$value" | xargs)
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
