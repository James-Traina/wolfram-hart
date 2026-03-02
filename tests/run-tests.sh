#!/usr/bin/env bash
#
# run-tests.sh — minimal test runner for wolfram-hart
#
# Usage:
#   bash tests/run-tests.sh                    # run all batches
#   bash tests/run-tests.sh tests/batch-01.sh  # run one batch
#   bash tests/run-tests.sh tests/batch-01.sh tests/batch-02.sh  # run specific batches
#

set -uo pipefail  # -e deliberately omitted: test functions return non-zero on failure

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source helpers — abort immediately if this fails
source "$SCRIPT_DIR/helpers.sh" || { echo "FATAL: cannot load helpers.sh"; exit 1; }

# Counters
PASS_COUNT=0
FAIL_COUNT=0
SKIP_COUNT=0
TOTAL_COUNT=0
FAILED_TESTS=()

# Determine which batch files to run
if [[ $# -gt 0 ]]; then
    BATCH_FILES=("$@")
else
    BATCH_FILES=("$SCRIPT_DIR"/batch-*.sh)
fi

echo "========================================"
echo " wolfram-hart test suite"
echo "========================================"
echo ""

for batch_file in "${BATCH_FILES[@]}"; do
    if [[ ! -f "$batch_file" ]]; then
        echo "WARNING: batch file not found: $batch_file"
        continue
    fi

    batch_name=$(basename "$batch_file" .sh)
    echo "--- $batch_name ---"

    # Snapshot current test_ functions before sourcing the batch
    _pre_funcs=$(declare -F | awk '{print $3}' | grep '^test_' | sort)

    # Source the batch file to define test functions
    source "$batch_file"

    # Discover only the NEW test_ functions added by this batch
    _post_funcs=$(declare -F | awk '{print $3}' | grep '^test_' | sort)
    test_funcs=($(comm -13 <(echo "$_pre_funcs") <(echo "$_post_funcs")))

    if [[ ${#test_funcs[@]} -eq 0 ]]; then
        echo "  WARNING: no test_ functions found in $batch_file"
        echo ""
        continue
    fi

    for func in "${test_funcs[@]}"; do
        TOTAL_COUNT=$((TOTAL_COUNT + 1))
        echo "[$TOTAL_COUNT] $func"

        # Reset per-test failure flag before running
        _CURRENT_TEST_FAILED=0

        # Run test, capture last-command exit code
        result=0
        $func || result=$?

        # A test fails if: the function returned non-zero OR any assertion set the flag
        if [[ $result -eq 2 ]]; then
            SKIP_COUNT=$((SKIP_COUNT + 1))
        elif [[ $result -ne 0 || $_CURRENT_TEST_FAILED -ne 0 ]]; then
            FAIL_COUNT=$((FAIL_COUNT + 1))
            FAILED_TESTS+=("$func")
        else
            PASS_COUNT=$((PASS_COUNT + 1))
        fi
        echo ""
    done

    # Unset the test functions so they don't carry into the next batch
    for func in "${test_funcs[@]}"; do
        unset -f "$func"
    done
done

echo "========================================"
echo " Results: $PASS_COUNT passed, $FAIL_COUNT failed, $SKIP_COUNT skipped (of $TOTAL_COUNT)"
echo "========================================"

if [[ ${#FAILED_TESTS[@]} -gt 0 ]]; then
    echo ""
    echo "Failed tests:"
    for t in "${FAILED_TESTS[@]}"; do
        echo "  - $t"
    done
fi

echo ""
if [[ $FAIL_COUNT -eq 0 ]]; then
    echo "ALL TESTS PASSED"
    exit 0
else
    echo "SOME TESTS FAILED"
    exit 1
fi
