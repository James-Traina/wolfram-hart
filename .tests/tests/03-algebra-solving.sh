#!/usr/bin/env bash
# Algebra & solving — Solve, Factor, Expand, Simplify, NSolve
# Sourced by run-all.sh. Defines test_* functions; do not execute directly.

test_021_quadratic() {
    run_eval 'Solve[x^2 - 4 == 0, x]'
    assert_contains "$LAST_STDOUT" "x -> 2" "quadratic roots should contain x -> 2"
    assert_contains "$LAST_STDOUT" "x -> -2" "quadratic roots should contain x -> -2"
}

test_022_cubic() {
    run_eval 'Solve[x^3 - 6 x^2 + 11 x - 6 == 0, x]'
    assert_contains "$LAST_STDOUT" "x -> 1" "cubic should have root x -> 1"
    assert_contains "$LAST_STDOUT" "x -> 2" "cubic should have root x -> 2"
    assert_contains "$LAST_STDOUT" "x -> 3" "cubic should have root x -> 3"
}

test_023_factor() {
    run_eval 'Factor[x^2 - 5 x + 6]'
    # Should contain (x-2) and (x-3) in some form, e.g. (-3 + x) (-2 + x)
    assert_contains "$LAST_STDOUT" "3" "factored form should reference 3"
    assert_contains "$LAST_STDOUT" "2" "factored form should reference 2"
    assert_contains "$LAST_STDOUT" "x" "factored form should contain x"
}

test_024_expand() {
    run_eval 'Expand[(x+1)^5]'
    assert_contains "$LAST_STDOUT" "x^5" "expansion should contain x^5"
    # 5*x^4 may render as 5 x^4 or 5*x^4
    assert_contains "$LAST_STDOUT" "x^4" "expansion should contain x^4 term"
}

test_025_trig_identity() {
    run_eval 'Simplify[Sin[x]^2 + Cos[x]^2]'
    assert_eq "$(echo "$LAST_STDOUT" | head -1)" "1" "sin^2 + cos^2 should simplify to 1"
}

test_026_partial_fractions() {
    run_eval 'Apart[1/(x^2 - 1)]'
    # Partial fractions of 1/(x^2-1) = 1/(2(x-1)) - 1/(2(x+1))
    assert_contains "$LAST_STDOUT" "(-1 + x)" "partial fractions should contain (x-1) term"
}

test_027_nsolve_quintic() {
    run_eval 'Length[NSolve[x^5 - x + 1 == 0, x]]' 60
    assert_eq "$(echo "$LAST_STDOUT" | head -1)" "5" "quintic should have 5 solutions"
}

test_028_reduce_inequality() {
    run_eval 'Reduce[x^2 < 4, x]'
    assert_contains "$LAST_STDOUT" "-2" "inequality should reference -2"
    assert_contains "$LAST_STDOUT" "2" "inequality should reference 2"
}

test_029_fullsimplify_sqrt_x2() {
    run_eval 'FullSimplify[Sqrt[x^2], Assumptions -> x > 0]'
    assert_eq "$(echo "$LAST_STDOUT" | head -1)" "x" "Sqrt[x^2] with x>0 should be x"
}

test_030_findroot() {
    run_eval 'FindRoot[Cos[x] == x, {x, 1}]'
    assert_contains "$LAST_STDOUT" "0.739" "Dottie number should be ~0.739"
}
