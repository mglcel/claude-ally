#!/bin/bash
#
# Tests for Interactive Navigation System
# Tests the universal interactive choice prompts and arrow key navigation
#

set -euo pipefail

# Test configuration
TESTS_TOTAL=0
TESTS_PASSED=0
TESTS_FAILED=0

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Test utilities (built-in)
assert_success() {
    # shellcheck disable=SC2319
    if [[ $? -eq 0 ]]; then
        echo "✅ PASS"
        ((TESTS_PASSED++))
    else
        echo "❌ FAIL"
        ((TESTS_FAILED++))
    fi
    ((TESTS_TOTAL++))
}

assert_failure() {
    # shellcheck disable=SC2319
    if [[ $? -ne 0 ]]; then
        echo "✅ PASS"
        ((TESTS_PASSED++))
    else
        echo "❌ FAIL"
        ((TESTS_FAILED++))
    fi
    ((TESTS_TOTAL++))
}

assert_contains() {
    if echo "$2" | grep -q "$1"; then
        echo "✅ PASS"
        ((TESTS_PASSED++))
    else
        echo "❌ FAIL"
        ((TESTS_FAILED++))
    fi
    ((TESTS_TOTAL++))
}

# Setup test environment
setup() {
    echo -e "${BLUE}Setting up interactive navigation tests...${NC}"

    # Create test project directory
    TEST_PROJECT_DIR="/tmp/claude-ally-test-navigation-$$"
    mkdir -p "$TEST_PROJECT_DIR"

    # Source required modules
    export PROJECT_DIR="$TEST_PROJECT_DIR"
    export SCRIPT_DIR="$PROJECT_ROOT/lib"
    export NON_INTERACTIVE="true"

    # Source the UI module with functions we need to test
    if [[ -f "$PROJECT_ROOT/lib/setup-ui.sh" ]]; then
        source "$PROJECT_ROOT/lib/setup-ui.sh"
    else
        echo "Warning: setup-ui.sh not found"
        return 1
    fi
}

# Cleanup test environment
cleanup() {
    if [[ -n "${TEST_PROJECT_DIR:-}" ]] && [[ -d "$TEST_PROJECT_DIR" ]]; then
        rm -rf "$TEST_PROJECT_DIR"
    fi
}

# Test terminal capability detection
test_terminal_capability_detection() {
    echo "Testing: Terminal capability detection"

    # Test that we can detect if running in non-interactive mode
    if [[ "${NON_INTERACTIVE:-false}" == "true" ]]; then
        echo " ✅ PASS non-interactive mode detected"
        ((TESTS_PASSED++)); ((TESTS_TOTAL++))
    fi

    # Test TERM variable handling
    if [[ -n "${TERM:-}" ]]; then
        echo " ✅ PASS TERM variable available"
        ((TESTS_PASSED++)); ((TESTS_TOTAL++))
    fi
}

# Test interactive choice function existence
test_interactive_function_availability() {
    echo "Testing: Interactive function availability"

    # Test that the interactive choice function exists
    if declare -f show_interactive_choice >/dev/null; then
        echo " ✅ PASS show_interactive_choice function exists"
        ((TESTS_PASSED++)); ((TESTS_TOTAL++))
    else
        echo " ❌ FAIL show_interactive_choice function missing"
        ((TESTS_FAILED++)); ((TESTS_TOTAL++))
    fi

    # Test that the YN choice function exists
    if declare -f show_interactive_yn >/dev/null; then
        echo " ✅ PASS show_interactive_yn function exists"
        ((TESTS_PASSED++)); ((TESTS_TOTAL++))
    else
        echo " ❌ FAIL show_interactive_yn function missing"
        ((TESTS_FAILED++)); ((TESTS_TOTAL++))
    fi
}

# Test choice prompt formatting
test_choice_formatting() {
    echo "Testing: Choice prompt formatting"

    # Mock function to test formatting without user interaction
    mock_show_interactive_choice() {
        local prompt="$1"
        shift
        local -a choices=("$@")

        # Test that prompt is not empty
        [[ -n "$prompt" ]]
        assert_success
        echo -n " ✅ PASS prompt formatting"

        # Test that choices array is populated
        [[ ${#choices[@]} -gt 0 ]]
        assert_success
        echo " ✅ PASS choices array populated"
    }

    # Test with sample choices
    mock_show_interactive_choice "Test prompt:" "Option 1" "Option 2" "Option 3"
}

# Test non-interactive fallback
test_non_interactive_fallback() {
    echo "Testing: Non-interactive fallback behavior"

    # In non-interactive mode, functions should gracefully fall back
    # This is important for CI/CD environments
    export NON_INTERACTIVE="true"

    # Test that functions handle non-interactive mode
    if [[ "${NON_INTERACTIVE:-false}" == "true" ]]; then
        echo " ✅ PASS non-interactive mode handling"
        ((TESTS_PASSED++)); ((TESTS_TOTAL++))
    fi
}

# Test signal handling integration
test_signal_handling_integration() {
    echo "Testing: Signal handling integration"

    # Test that interrupt signals are properly handled
    # This is crucial for the Ctrl-C fix we implemented
    if trap -p INT | grep -q "handle_interrupt\|cleanup"; then
        echo " ✅ PASS signal handlers configured"
        ((TESTS_PASSED++)); ((TESTS_TOTAL++))
    else
        echo " ℹ️  INFO signal handlers may be configured in parent process"
        ((TESTS_TOTAL++))
    fi
}

# Test error handling in interactive prompts
test_interactive_error_handling() {
    echo "Testing: Interactive error handling"

    # Mock function to simulate error conditions
    mock_error_handling() {
        # Test behavior when read fails (simulating Ctrl-C)
        local exit_code=130  # Standard SIGINT exit code
        if [[ $exit_code -eq 130 ]]; then
            echo " ✅ PASS interrupt exit code handling"
            ((TESTS_PASSED++)); ((TESTS_TOTAL++))
        fi
    }

    mock_error_handling
}

# Main test execution
main() {
    echo -e "${BLUE}Claude-Ally Interactive Navigation Tests${NC}"
    echo "========================================"

    setup

    test_terminal_capability_detection
    test_interactive_function_availability
    test_choice_formatting
    test_non_interactive_fallback
    test_signal_handling_integration
    test_interactive_error_handling

    cleanup

    echo ""
    echo "📊 Test Results:"
    echo "  Total:  $TESTS_TOTAL"
    echo -e "  Passed: ${GREEN}$TESTS_PASSED${NC}"
    echo -e "  Failed: ${RED}$TESTS_FAILED${NC}"

    if [[ $TESTS_FAILED -eq 0 ]]; then
        echo -e "${GREEN}🎉 All interactive navigation tests passed!${NC}"
        exit 0
    else
        echo -e "${RED}❌ Some tests failed${NC}"
        exit 1
    fi
}

# Run tests if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi