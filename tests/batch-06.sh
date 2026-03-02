#!/usr/bin/env bash
# Batch 6: Output Formatting (tests 051-060)
# Sourced by run-tests.sh. Defines test_* functions; do not execute directly.

test_051_texform() {
    run_eval 'ToString[TeXForm[x^2/3]]'
    assert_contains "$LAST_STDOUT" "frac" "TeXForm should produce LaTeX with frac"
}

test_052_texform_integral() {
    run_eval 'ToString[TeXForm[Integrate[x^2, x]]]'
    assert_contains "$LAST_STDOUT" "frac" "LaTeX integral should contain frac"
    assert_contains "$LAST_STDOUT" "x^3" "LaTeX integral should contain x^3"
}

test_053_json_export_list() {
    run_eval 'ExportString[{1,2,3}, "JSON"]'
    assert_contains "$LAST_STDOUT" "[" "JSON array should have ["
    assert_contains "$LAST_STDOUT" "1" "JSON array should contain 1"
    assert_contains "$LAST_STDOUT" "3" "JSON array should contain 3"
}

test_054_json_export_association() {
    run_eval 'ExportString[<|"a" -> 1, "b" -> 2|>, "JSON"]'
    assert_contains "$LAST_STDOUT" '"a"' "JSON should contain key a"
    assert_contains "$LAST_STDOUT" '"b"' "JSON should contain key b"
}

test_055_csv_export() {
    run_eval 'ExportString[{{1,2},{3,4}}, "CSV"]'
    assert_contains "$LAST_STDOUT" "," "CSV should contain commas"
    assert_contains "$LAST_STDOUT" "1" "CSV should contain 1"
    assert_contains "$LAST_STDOUT" "4" "CSV should contain 4"
}

test_056_inputform() {
    run_eval 'ToString[{1, 2, 3}, InputForm]'
    assert_contains "$LAST_STDOUT" "{1, 2, 3}" "InputForm should produce {1, 2, 3}"
}

test_057_stringriffle_newlines() {
    run_eval 'StringRiffle[{"a","b","c"}, "\n"]'
    # Output should have multiple lines
    local line_count
    line_count=$(echo "$LAST_STDOUT" | grep -c '^' || true)
    [[ $line_count -ge 3 ]] && _pass "StringRiffle produces multiple lines ($line_count)" || _fail "StringRiffle should produce at least 3 lines (got $line_count)"
}

test_058_module_stringriffle() {
    run_eval 'Module[{items}, items = {"line1", "line2", "line3"}; StringRiffle[items, "\n"]]'
    assert_contains "$LAST_STDOUT" "line1" "Module+StringRiffle should have line1"
    assert_contains "$LAST_STDOUT" "line3" "Module+StringRiffle should have line3"
}

test_059_tostring_clean() {
    run_eval 'ToString[Solve[x^2 == 4, x]]'
    assert_eq "$LAST_EXIT" "0" "ToString should succeed"
    # Should not contain OutputForm wrapper or anything weird
    assert_not_contains "$LAST_STDOUT" "OutputForm" "should not have OutputForm wrapper"
}

test_060_nested_list_format() {
    run_eval '{{1, 0}, {0, 1}}'
    assert_contains "$LAST_STDOUT" "1" "nested list should contain 1"
    assert_contains "$LAST_STDOUT" "0" "nested list should contain 0"
}
