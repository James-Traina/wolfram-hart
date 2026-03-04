#!/usr/bin/env bash
# Edge cases & error handling — misspellings, exit codes, Unicode
# Sourced by run-all.sh. Defines test_* functions; do not execute directly.

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

test_101_exit_code_1_no_wolframscript() {
    # Simulate a system where wolframscript is not installed by replacing the
    # discovery helper (_find-wolframscript.sh) with a stub that sets WOLFRAMSCRIPT="".
    # We copy wolfram-eval.sh to a temp dir so dirname "${BASH_SOURCE[0]}" resolves
    # there and sources our stub instead of the real discovery script.
    local stub_dir exit_code=0 out
    stub_dir=$(mktemp -d "${TMPDIR:-/tmp}/wolfram_no_ws_XXXXXX")
    printf '#!/usr/bin/env bash\nWOLFRAMSCRIPT=""\n' > "$stub_dir/_find-wolframscript.sh"
    cp "$EVAL_SCRIPT" "$stub_dir/wolfram-eval.sh"
    out=$(bash "$stub_dir/wolfram-eval.sh" '2+2' 2>/dev/null) || exit_code=$?
    LAST_EXIT=$exit_code
    LAST_STDOUT="$out"
    rm -rf "$stub_dir"
    assert_eq "$LAST_EXIT" "1" "missing wolframscript should exit 1"
    assert_contains "$LAST_STDOUT" "NOT_INSTALLED" "exit 1 output should contain NOT_INSTALLED"
}

test_102_exit_code_2_execution_error() {
    # Simulate wolframscript found but crashing with no output (execution error).
    # A stub wolframscript exits 1 with no output; WOLFRAM_MODE=local prevents
    # auto-mode from retrying in the cloud and masking the error.
    local stub_dir exit_code=0 out
    stub_dir=$(mktemp -d "${TMPDIR:-/tmp}/wolfram_err_ws_XXXXXX")
    printf 'WOLFRAMSCRIPT="%s/wolframscript"\n' "$stub_dir" > "$stub_dir/_find-wolframscript.sh"
    printf '#!/usr/bin/env bash\nexit 1\n' > "$stub_dir/wolframscript"
    chmod +x "$stub_dir/wolframscript"
    cp "$EVAL_SCRIPT" "$stub_dir/wolfram-eval.sh"
    out=$(WOLFRAM_MODE=local bash "$stub_dir/wolfram-eval.sh" '2+2' 2>/dev/null) || exit_code=$?
    LAST_EXIT=$exit_code
    LAST_STDOUT="$out"
    rm -rf "$stub_dir"
    assert_eq "$LAST_EXIT" "2" "execution error with no output should exit 2"
    assert_contains "$LAST_STDOUT" "ERROR" "exit 2 output should contain ERROR"
}
