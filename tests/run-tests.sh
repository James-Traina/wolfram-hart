#!/usr/bin/env bash
#
# run-tests.sh — minimal test runner for wolfram-skill
#
# Usage:
#   bash tests/run-tests.sh                    # run all batches
#   bash tests/run-tests.sh tests/batch-01.sh  # run one batch
#   bash tests/run-tests.sh tests/batch-01.sh tests/batch-02.sh  # run specific batches
#

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source helpers
source "$SCRIPT_DIR/helpers.sh"

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
echo " wolfram-skill test suite"
echo "========================================"
echo ""

for batch_file in "${BATCH_FILES[@]}"; do
    if [[ ! -f "$batch_file" ]]; then
        echo "WARNING: batch file not found: $batch_file"
        continue
    fi

    batch_name=$(basename "$batch_file" .sh)
    echo "--- $batch_name ---"

    # Source the batch file to define test functions
    source "$batch_file"

    # Discover test_* functions defined in this batch
    test_funcs=($(declare -F | awk '{print $3}' | grep '^test_' | sort))

    for func in "${test_funcs[@]}"; do
        TOTAL_COUNT=$((TOTAL_COUNT + 1))
        echo "[$TOTAL_COUNT] $func"

        # Run test, capture result
        result=0
        $func || result=$?

        if [[ $result -eq 0 ]]; then
            PASS_COUNT=$((PASS_COUNT + 1))
        elif [[ $result -eq 2 ]]; then
            SKIP_COUNT=$((SKIP_COUNT + 1))
        else
            FAIL_COUNT=$((FAIL_COUNT + 1))
            FAILED_TESTS+=("$func")
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
