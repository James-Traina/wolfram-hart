#!/usr/bin/env bash
# Number theory & transforms — primes, GCD, Fourier, Laplace
# Sourced by run-all.sh. Defines test_* functions; do not execute directly.

test_071_factor_integer() {
    run_eval 'FactorInteger[360]'
    assert_contains "$LAST_STDOUT" "{2, 3}" "360 factorization should contain {2,3} (2^3)"
    assert_contains "$LAST_STDOUT" "{3, 2}" "360 factorization should contain {3,2} (3^2)"
}

test_072_nth_prime() {
    run_eval 'Prime[100]'
    assert_eq "$(echo "$LAST_STDOUT" | head -1)" "541" "100th prime should be 541"
}

test_073_next_prime() {
    run_eval 'NextPrime[100]'
    assert_eq "$(echo "$LAST_STDOUT" | head -1)" "101" "next prime after 100 should be 101"
}

test_074_gcd() {
    run_eval 'GCD[12, 18]'
    assert_eq "$(echo "$LAST_STDOUT" | head -1)" "6" "GCD(12,18) should be 6"
}

test_075_euler_phi() {
    run_eval 'EulerPhi[100]'
    assert_eq "$(echo "$LAST_STDOUT" | head -1)" "40" "EulerPhi(100) should be 40"
}

test_076_mod() {
    run_eval 'Mod[17, 5]'
    assert_eq "$(echo "$LAST_STDOUT" | head -1)" "2" "17 mod 5 should be 2"
}

test_077_fourier_transform() {
    run_eval 'FourierTransform[Exp[-t^2], t, w]'
    assert_contains "$LAST_STDOUT" "E" "Fourier of Gaussian should contain E"
}

test_078_laplace_transform() {
    run_eval 'LaplaceTransform[Sin[t], t, s]'
    # Should be 1/(1+s^2)
    assert_contains "$LAST_STDOUT" "s^2" "Laplace of sin(t) should contain s^2"
}

test_079_inverse_laplace() {
    run_eval 'InverseLaplaceTransform[1/(s^2 + 1), s, t]'
    assert_contains "$LAST_STDOUT" "Sin" "inverse Laplace should contain Sin"
}

test_080_powermod() {
    run_eval 'PowerMod[2, 100, 97]'
    local first_line
    first_line=$(echo "$LAST_STDOUT" | head -1)
    assert_numeric "$first_line" "PowerMod should return a number"
}
