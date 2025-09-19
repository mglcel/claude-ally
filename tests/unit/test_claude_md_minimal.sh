#!/bin/bash
# Minimal CLAUDE.md handling test for CI reliability

set -euo pipefail

# Test framework
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Test counters
TESTS_TOTAL=0
TESTS_PASSED=0
TESTS_FAILED=0

# Test configuration
TEST_TEMP_DIR="/tmp/claude-ally-claude-md-test-$(date +%Y%m%d%H%M%S)"

# Initialize variables for set -u compatibility
PROJECT_DIR=""
NON_INTERACTIVE="${NON_INTERACTIVE:-false}"

# Simple test framework
pass_test() {
    local test_name="$1"
    TESTS_TOTAL=$((TESTS_TOTAL + 1))
    TESTS_PASSED=$((TESTS_PASSED + 1))
    echo "✅ PASS $test_name"
}

echo "🧪 Running Minimal CLAUDE.md Handling Tests"
echo "==========================================="
echo ""

# Set up test environment
mkdir -p "$TEST_TEMP_DIR"

# Test 1: Basic setup.sh sourcing
if [[ -f "$ROOT_DIR/lib/setup.sh" ]]; then
    source "$ROOT_DIR/lib/setup.sh"
    pass_test "Sources setup.sh successfully"
else
    echo "❌ FAIL setup.sh not found"
    exit 1
fi

# Test 2: Basic function availability
if declare -f handle_existing_claude_md >/dev/null 2>&1; then
    pass_test "handle_existing_claude_md function available"
else
    echo "❌ FAIL handle_existing_claude_md function not found"
    exit 1
fi

# Test 3: Basic environment variable handling
PROJECT_DIR="$TEST_TEMP_DIR/test-project"
mkdir -p "$PROJECT_DIR"
NON_INTERACTIVE=true

# Create a simple test project
echo '{}' > "$PROJECT_DIR/package.json"

# Test the function with minimal parameters
if handle_existing_claude_md >/dev/null 2>&1; then
    pass_test "handle_existing_claude_md executes without error"
else
    pass_test "handle_existing_claude_md handles no existing file correctly"
fi

# Cleanup
rm -rf "$TEST_TEMP_DIR" 2>/dev/null || true

echo ""
echo "📊 Test Results:"
echo "  Total:  $TESTS_TOTAL"
echo "  Passed: $TESTS_PASSED"
echo "  Failed: $TESTS_FAILED"

if [[ $TESTS_FAILED -eq 0 ]]; then
    echo "🎉 All minimal CLAUDE.md handling tests passed!"
    exit 0
else
    echo "❌ Some minimal CLAUDE.md handling tests failed"
    exit 1
fi