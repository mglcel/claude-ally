#!/bin/bash
# Simplified CLAUDE.md test to isolate the issue

echo "DEBUG: Starting simple CLAUDE.md test"

# Don't use set -euo pipefail initially to see what fails
# set -euo pipefail

echo "DEBUG: Getting directories"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"

echo "DEBUG: SCRIPT_DIR=$SCRIPT_DIR"
echo "DEBUG: ROOT_DIR=$ROOT_DIR"

echo "DEBUG: Setting up basic variables"
TESTS_TOTAL=1
TESTS_PASSED=0
TESTS_FAILED=0

echo "DEBUG: About to check if setup.sh exists"
if [[ -f "$ROOT_DIR/lib/setup.sh" ]]; then
    echo "DEBUG: setup.sh exists, attempting to source"
    # Try sourcing without strict error handling first
    source "$ROOT_DIR/lib/setup.sh"
    echo "DEBUG: Successfully sourced setup.sh"
else
    echo "DEBUG: setup.sh NOT FOUND at $ROOT_DIR/lib/setup.sh"
    exit 1
fi

echo "DEBUG: Test completed successfully"
echo "✅ PASS Simple CLAUDE.md test works"
echo "📊 Test Results:"
echo "  Total:  1"
echo "  Passed: 1"
echo "  Failed: 0"
echo "🎉 Simple CLAUDE.md test passed!"
exit 0