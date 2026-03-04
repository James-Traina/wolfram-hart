#!/usr/bin/env bash
# Script mechanics — eval, exit codes, timeouts, temp files
# Sourced by run-all.sh. Defines test_* functions; do not execute directly.

test_001_basic_eval() {
    run_eval '2+2'
    assert_eq "$(echo "$LAST_STDOUT" | head -1)" "4" "2+2 should return 4"
}

test_002_exit_code_zero_on_success() {
    run_eval '2+2'
    assert_eq "$LAST_EXIT" "0" "successful eval should exit 0"
}

test_003_timeout_exit_code() {
    run_eval 'Pause[5]' 1
    assert_eq "$LAST_EXIT" "3" "timeout should exit 3"
}

test_004_timeout_message() {
    run_eval 'Pause[5]' 1
    assert_contains "$LAST_STDOUT" "TIMEOUT" "timeout output should contain TIMEOUT"
}

test_005_missing_argument() {
    local exit_code=0
    bash "$EVAL_SCRIPT" 2>/dev/null || exit_code=$?
    [[ $exit_code -ne 0 ]] && _pass "missing argument exits non-zero (exit $exit_code)" || _fail "missing argument should exit non-zero"
}

test_006_temp_files_cleaned() {
    local before after
    before=$(ls "${TMPDIR:-/tmp}"/wolfram_* 2>/dev/null | wc -l)
    run_eval '2+2'
    after=$(ls "${TMPDIR:-/tmp}"/wolfram_* 2>/dev/null | wc -l)
    assert_eq "$after" "$before" "temp files should be cleaned up"
}

test_007_warnings_in_output() {
    # 1/0 produces a Power::infy warning; wolframscript sends it inline on stdout
    # The ---WARNINGS--- marker fires only when wolframscript writes to stderr,
    # which varies by version. We check the warning is visible somewhere.
    run_eval '1/0'
    local combined="$LAST_STDOUT $LAST_STDERR"
    if [[ "$combined" == *"---WARNINGS---"* ]]; then
        _pass "warnings appear after ---WARNINGS--- marker"
    elif [[ "$combined" == *"Power::infy"* || "$combined" == *"Infinite expression"* ]]; then
        _pass "warning appears inline in output"
    else
        _fail "no warning visible for 1/0 (stdout: ${LAST_STDOUT:0:200})"
    fi
    assert_contains "$LAST_STDOUT" "ComplexInfinity" "result should still contain ComplexInfinity"
}

test_008_nonzero_exit_with_output() {
    # When wolframscript returns a warning but produces output, we still get the result
    run_eval 'Check[1/0, ComplexInfinity]'
    assert_eq "$LAST_EXIT" "0" "partial-success should still exit 0"
    assert_contains "$LAST_STDOUT" "ComplexInfinity" "should contain the result"
}

test_009_custom_timeout_accepted() {
    run_eval '2+2' 60
    assert_eq "$LAST_EXIT" "0" "custom timeout 60 should be accepted"
    assert_eq "$(echo "$LAST_STDOUT" | head -1)" "4" "result should still be correct"
}

test_010_large_output() {
    run_eval 'Range[10000]' 60
    assert_eq "$LAST_EXIT" "0" "large output should succeed"
    assert_contains "$LAST_STDOUT" "10000" "should contain last element 10000"
    assert_contains "$LAST_STDOUT" "1," "should contain first elements"
}
