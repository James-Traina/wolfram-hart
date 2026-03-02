#!/usr/bin/env bash
# Batch 10: Edge Cases & Error Handling (tests 091-100)
# Sourced by run-tests.sh. Defines test_* functions; do not execute directly.

test_091_unevaluated_misspelling() {
    run_eval 'Solvee[x^2 == 4, x]'
    assert_contains "$LAST_STDOUT" "Solvee" "misspelled function should return unevaluated"
}

test_092_check_error() {
    run_eval 'Check[1/0, "ERROR"]'
    assert_contains "$LAST_STDOUT" "ERROR" "Check should catch 1/0 and return ERROR"
}

test_093_quiet_suppression() {
    run_eval 'Quiet[1/0]'
    # Should succeed without crashing; result is ComplexInfinity
    assert_eq "$LAST_EXIT" "0" "Quiet should succeed"
    assert_contains "$LAST_STDOUT" "ComplexInfinity" "Quiet[1/0] should return ComplexInfinity"
}

test_094_time_constrained() {
    run_eval 'TimeConstrained[Pause[10], 2, "TIMEOUT"]'
    assert_contains "$LAST_STDOUT" "TIMEOUT" "TimeConstrained should return TIMEOUT"
}

test_095_special_chars_in_strings() {
    run_eval 'StringJoin["dollar:", ToString[36], " hash:", ToString[35], " amp:", ToString[38]]'
    assert_eq "$LAST_EXIT" "0" "special chars in strings should not break shell"
}

test_096_long_code_string() {
    # Build a long code string with many additions
    local long_code="Module[{s = 0},"
    for i in $(seq 1 200); do
        long_code+=" s += $i;"
    done
    long_code+=" s]"
    run_eval "$long_code" 60
    assert_eq "$LAST_EXIT" "0" "long code string should execute"
    # Sum 1..200 = 20100
    assert_contains "$LAST_STDOUT" "20100" "sum 1..200 should be 20100"
}

test_097_unicode_in_strings() {
    run_eval 'StringJoin[FromCharacterCode[960], " ≈ 3.14"]'
    assert_eq "$LAST_EXIT" "0" "unicode should not crash"
}

test_098_empty_module() {
    run_eval 'Module[{}, 42]'
    assert_eq "$(echo "$LAST_STDOUT" | head -1)" "42" "empty Module should return 42"
}

test_099_nested_module() {
    run_eval 'Module[{a = 10}, Module[{b = 20}, a + b]]'
    assert_eq "$(echo "$LAST_STDOUT" | head -1)" "30" "nested Module should return 30"
}

test_100_semicolons_suppress() {
    run_eval 'a = 1; b = 2; c = 3; a + b + c'
    # Only the final expression (6) should be printed
    local first_line
    first_line=$(echo "$LAST_STDOUT" | head -1)
    assert_eq "$first_line" "6" "semicolons should suppress intermediate output"
}
