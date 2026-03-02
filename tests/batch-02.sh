#!/usr/bin/env bash
# Batch 2: Arithmetic & Constants (tests 011-020)

test_011_pi_precision() {
    run_eval 'N[Pi, 15]'
    assert_contains "$LAST_STDOUT" "3.14159265358979" "Pi to 15 digits"
}

test_012_euler_number() {
    run_eval 'N[E, 10]'
    assert_contains "$LAST_STDOUT" "2.718281828" "E to 10 digits"
}

test_013_sqrt2() {
    run_eval 'N[Sqrt[2], 10]'
    assert_contains "$LAST_STDOUT" "1.414213562" "Sqrt[2] to 10 digits"
}

test_014_factorial_100() {
    run_eval '100!'
    # 100! has 158 digits and starts with 9332...
    assert_contains "$LAST_STDOUT" "9332621544" "100! should start correctly"
    # Check it's a big number (at least 150 chars)
    local len=${#LAST_STDOUT}
    [[ $len -ge 150 ]] && _pass "100! has $len chars (>=150)" || _fail "100! output too short ($len chars)"
}

test_015_large_power() {
    run_eval '2^1000' 60
    assert_eq "$LAST_EXIT" "0" "2^1000 should succeed"
    # 2^1000 starts with 1071508607...
    assert_contains "$LAST_STDOUT" "10715086071862" "2^1000 starts correctly"
}

test_016_golden_ratio() {
    run_eval 'N[GoldenRatio, 10]'
    assert_contains "$LAST_STDOUT" "1.618033988" "GoldenRatio to 10 digits"
}

test_017_log_e() {
    run_eval 'Log[E]'
    assert_eq "$(echo "$LAST_STDOUT" | head -1)" "1" "Log[E] should be 1"
}

test_018_sin_pi() {
    run_eval 'Sin[Pi]'
    assert_eq "$(echo "$LAST_STDOUT" | head -1)" "0" "Sin[Pi] should be 0"
}

test_019_cos_pi_over_3() {
    run_eval 'Cos[Pi/3]'
    assert_contains "$LAST_STDOUT" "1/2" "Cos[Pi/3] should be 1/2"
}

test_020_primeq() {
    run_eval 'PrimeQ[17]'
    assert_eq "$(echo "$LAST_STDOUT" | head -1)" "True" "PrimeQ[17] should be True"
}
