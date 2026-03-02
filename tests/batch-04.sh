#!/usr/bin/env bash
# Batch 4: Calculus (tests 031-040)
# Sourced by run-tests.sh. Defines test_* functions; do not execute directly.

test_031_derivative() {
    run_eval 'D[x^3, x]'
    # Should be 3 x^2 or 3*x^2
    assert_contains "$LAST_STDOUT" "3" "derivative of x^3 should contain 3"
    assert_contains "$LAST_STDOUT" "x^2" "derivative of x^3 should contain x^2"
}

test_032_indefinite_integral() {
    run_eval 'Integrate[x^2, x]'
    assert_contains "$LAST_STDOUT" "x^3" "integral of x^2 should contain x^3"
    assert_contains "$LAST_STDOUT" "3" "integral of x^2 should contain /3"
}

test_033_definite_integral() {
    run_eval 'Integrate[Sin[x], {x, 0, Pi}]'
    assert_eq "$(echo "$LAST_STDOUT" | head -1)" "2" "integral of sin from 0 to pi is 2"
}

test_034_limit() {
    run_eval 'Limit[Sin[x]/x, x -> 0]'
    assert_eq "$(echo "$LAST_STDOUT" | head -1)" "1" "limit of sin(x)/x as x->0 is 1"
}

test_035_taylor_series() {
    run_eval 'Normal[Series[Exp[x], {x, 0, 3}]]'
    # Should contain x^3/6 in some form
    assert_contains "$LAST_STDOUT" "x^3" "Taylor of e^x should contain x^3"
    assert_contains "$LAST_STDOUT" "6" "Taylor of e^x to order 3 should contain 6 (from x^3/6)"
}

test_036_infinite_series() {
    run_eval 'Sum[1/n^2, {n, 1, Infinity}]'
    assert_contains "$LAST_STDOUT" "Pi" "Basel series should contain Pi"
    # Pi^2/6
    assert_contains "$LAST_STDOUT" "6" "Basel series should contain 6"
}

test_037_product_rule() {
    run_eval 'D[Sin[x]*Cos[x], x]'
    # The derivative is cos(2x) or cos^2(x) - sin^2(x)
    assert_contains "$LAST_STDOUT" "Cos" "derivative should contain Cos"
    assert_contains "$LAST_STDOUT" "Sin" "derivative should contain Sin"
}

test_038_arctan_integral() {
    run_eval 'Integrate[1/(1+x^2), x]'
    assert_contains "$LAST_STDOUT" "ArcTan" "integral should be ArcTan"
}

test_039_euler_limit() {
    run_eval 'Limit[(1 + 1/n)^n, n -> Infinity]'
    # Should return E
    local first_line
    first_line=$(echo "$LAST_STDOUT" | head -1)
    assert_eq "$first_line" "E" "limit should be E"
}

test_040_double_integral() {
    run_eval 'Integrate[x*y, {x, 0, 1}, {y, 0, 1}]'
    assert_contains "$LAST_STDOUT" "1/4" "double integral of x*y should be 1/4"
}
