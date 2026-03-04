#!/usr/bin/env bash
# Linear algebra — determinants, eigenvalues, inverse, solve
# Sourced by run-all.sh. Defines test_* functions; do not execute directly.

test_041_determinant_2x2() {
    run_eval 'Det[{{1,2},{3,4}}]'
    assert_eq "$(echo "$LAST_STDOUT" | head -1)" "-2" "2x2 determinant should be -2"
}

test_042_inverse_identity() {
    run_eval 'Inverse[{{1,0},{0,1}}]'
    assert_contains "$LAST_STDOUT" "{1, 0}" "identity inverse should contain {1, 0}"
    assert_contains "$LAST_STDOUT" "{0, 1}" "identity inverse should contain {0, 1}"
}

test_043_eigenvalues() {
    run_eval 'Sort[Eigenvalues[{{2,1},{1,2}}]]'
    assert_contains "$LAST_STDOUT" "1" "eigenvalues should contain 1"
    assert_contains "$LAST_STDOUT" "3" "eigenvalues should contain 3"
}

test_044_matrix_rank() {
    run_eval 'MatrixRank[{{1,2,3},{4,5,6},{7,8,9}}]'
    assert_eq "$(echo "$LAST_STDOUT" | head -1)" "2" "rank of singular matrix should be 2"
}

test_045_transpose() {
    run_eval 'Transpose[{{1,2},{3,4}}]'
    assert_contains "$LAST_STDOUT" "{1, 3}" "transpose should have {1,3}"
    assert_contains "$LAST_STDOUT" "{2, 4}" "transpose should have {2,4}"
}

test_046_linear_solve() {
    run_eval 'LinearSolve[{{1,2},{3,4}}, {5,6}]'
    assert_eq "$LAST_EXIT" "0" "LinearSolve should succeed"
    assert_contains "$LAST_STDOUT" "-4" "solution should contain -4"
}

test_047_identity_matrix() {
    run_eval 'IdentityMatrix[3]'
    assert_contains "$LAST_STDOUT" "{1, 0, 0}" "identity should have {1,0,0}"
    assert_contains "$LAST_STDOUT" "{0, 1, 0}" "identity should have {0,1,0}"
    assert_contains "$LAST_STDOUT" "{0, 0, 1}" "identity should have {0,0,1}"
}

test_048_char_polynomial() {
    run_eval 'CharacteristicPolynomial[{{1,2},{3,4}}, x]'
    assert_contains "$LAST_STDOUT" "x" "char polynomial should contain x"
    assert_eq "$LAST_EXIT" "0" "char polynomial should succeed"
}

test_049_null_space() {
    run_eval 'NullSpace[{{1,2,3},{4,5,6},{7,8,9}}]'
    assert_eq "$LAST_EXIT" "0" "NullSpace should succeed"
    # Should be non-empty (singular matrix)
    assert_not_contains "$LAST_STDOUT" "{}" "null space should be non-empty"
}

test_050_determinant_3x3() {
    run_eval 'Det[{{1,2,3},{4,5,6},{7,8,10}}]'
    assert_eq "$(echo "$LAST_STDOUT" | head -1)" "-3" "3x3 determinant should be -3"
}
