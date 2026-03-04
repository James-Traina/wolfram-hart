#!/usr/bin/env bash
# Statistics, probability & units — mean, PDF, CDF, UnitConvert
# Sourced by run-all.sh. Defines test_* functions; do not execute directly.

test_081_mean() {
    run_eval 'Mean[{1,2,3,4,5}]'
    assert_eq "$(echo "$LAST_STDOUT" | head -1)" "3" "mean of 1..5 should be 3"
}

test_082_median() {
    run_eval 'Median[{1,2,3,4,5}]'
    assert_eq "$(echo "$LAST_STDOUT" | head -1)" "3" "median of 1..5 should be 3"
}

test_083_std_dev() {
    # Wolfram uses sample std dev (n-1 denominator), so this is 4*Sqrt[2/7] ≈ 2.138
    run_eval 'N[StandardDeviation[{2,4,4,4,5,5,7,9}]]'
    assert_contains "$LAST_STDOUT" "2.13" "sample std dev should be ~2.138"
}

test_084_variance() {
    run_eval 'Variance[{1,2,3,4,5}]'
    # Wolfram uses sample variance (n-1 denominator): 5/2
    assert_eq "$(echo "$LAST_STDOUT" | head -1)" "5/2" "sample variance of 1..5 should be 5/2"
}

test_085_random_variate() {
    run_eval 'Length[RandomVariate[NormalDistribution[], 100]]'
    assert_eq "$(echo "$LAST_STDOUT" | head -1)" "100" "should generate 100 samples"
}

test_086_pdf_normal() {
    run_eval 'PDF[NormalDistribution[0, 1], 0]'
    local first_line
    first_line=$(echo "$LAST_STDOUT" | head -1)
    # Should be 1/Sqrt[2 Pi] or a numeric approximation
    if [[ "$first_line" == *"Pi"* || "$first_line" == *"Sqrt"* || "$first_line" == *"0.39"* ]]; then
        _pass "PDF at 0 contains expected form ($first_line)"
    else
        _fail "PDF at 0 should reference Pi/Sqrt or ~0.399 (got $first_line)"
    fi
}

test_087_cdf_normal() {
    run_eval 'CDF[NormalDistribution[0, 1], 0]'
    assert_contains "$LAST_STDOUT" "1/2" "CDF at 0 should be 1/2"
}

test_088_unit_convert_miles() {
    run_eval 'N[UnitConvert[Quantity[1, "Miles"], "Kilometers"]]' 60
    assert_contains "$LAST_STDOUT" "1.609" "1 mile should be ~1.609 km"
}

test_089_temperature_conversion() {
    run_eval 'N[UnitConvert[Quantity[100, "DegreesCelsius"], "DegreesFahrenheit"]]' 60
    assert_contains "$LAST_STDOUT" "212" "100C should be 212F"
}

test_090_linear_model_fit() {
    run_eval 'Module[{data, fit}, data = Table[{x, 2 x + 1}, {x, 0, 10}]; fit = LinearModelFit[data, x, x]; fit["BestFitParameters"]]' 60
    assert_eq "$LAST_EXIT" "0" "LinearModelFit should succeed"
    # Exact data: intercept = 1., slope = 2.
    assert_contains "$LAST_STDOUT" "1." "best fit should contain intercept 1."
    assert_contains "$LAST_STDOUT" "2." "best fit should contain slope 2."
}
