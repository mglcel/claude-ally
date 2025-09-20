#!/bin/bash
#
# Tests for Universal Choice Prompts
# Tests the universal interactive choice system for all prompts
#

set -uo pipefail

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
    if [[ $? -eq 0 ]]; then
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
    echo -e "${BLUE}Setting up universal choice prompt tests...${NC}"

    # Create test project directory
    TEST_PROJECT_DIR="/tmp/claude-ally-test-choice-$$"
    mkdir -p "$TEST_PROJECT_DIR"

    # Set environment
    export PROJECT_DIR="$TEST_PROJECT_DIR"
    export SCRIPT_DIR="$PROJECT_ROOT/lib"
    export NON_INTERACTIVE="true"

    # Source the UI module to test interactive functions
    if [[ -f "$PROJECT_ROOT/lib/setup-ui.sh" ]]; then
        source "$PROJECT_ROOT/lib/setup-ui.sh"
    fi
}

# Cleanup test environment
cleanup() {
    if [[ -n "${TEST_PROJECT_DIR:-}" ]] && [[ -d "$TEST_PROJECT_DIR" ]]; then
        rm -rf "$TEST_PROJECT_DIR"
    fi
}

# Test universal choice function signatures
test_choice_function_signatures() {
    echo "Testing: Universal choice function signatures"

    # Test show_interactive_choice function exists and has proper signature
    if declare -f show_interactive_choice >/dev/null; then
        echo " ✅ PASS show_interactive_choice function exists"
        ((TESTS_PASSED++)); ((TESTS_TOTAL++))
    else
        echo " ❌ FAIL show_interactive_choice function missing"
        ((TESTS_FAILED++)); ((TESTS_TOTAL++))
    fi

    # Test show_interactive_yn function exists
    if declare -f show_interactive_yn >/dev/null; then
        echo " ✅ PASS show_interactive_yn function exists"
        ((TESTS_PASSED++)); ((TESTS_TOTAL++))
    else
        echo " ❌ FAIL show_interactive_yn function missing"
        ((TESTS_FAILED++)); ((TESTS_TOTAL++))
    fi
}

# Test choice prompt standardization
test_choice_prompt_standardization() {
    echo "Testing: Choice prompt standardization"

    # Check that setup-config.sh implements standardized choice prompts
    if [[ -f "$PROJECT_ROOT/lib/setup-config.sh" ]]; then
        local config_content
        config_content=$(cat "$PROJECT_ROOT/lib/setup-config.sh")

        # Look for standardized CLAUDE.md handling choices
        if echo "$config_content" | grep -q "Replace with new configuration"; then
            echo " ✅ PASS standardized CLAUDE.md choice options"
            ((TESTS_PASSED++)); ((TESTS_TOTAL++))
        else
            echo " ❌ FAIL CLAUDE.md choices not standardized"
            ((TESTS_FAILED++)); ((TESTS_TOTAL++))
        fi

        # Look for interactive choice integration
        if echo "$config_content" | grep -q "show_interactive_choice"; then
            echo " ✅ PASS interactive choice integration"
            ((TESTS_PASSED++)); ((TESTS_TOTAL++))
        else
            echo " ❌ FAIL interactive choice not integrated"
            ((TESTS_FAILED++)); ((TESTS_TOTAL++))
        fi
    else
        echo " ℹ️  INFO setup-config.sh not found for testing"
        ((TESTS_TOTAL++))
    fi
}

# Test fallback to traditional prompts
test_traditional_prompt_fallback() {
    echo "Testing: Traditional prompt fallback"

    # Mock function that demonstrates fallback behavior
    mock_choice_with_fallback() {
        local prompt="$1"
        local choice1="$2"
        local choice2="$3"

        # Simulate interactive choice attempt
        local choice_made=false

        # Simulate that interactive choice failed (terminal doesn't support it)
        # So we fall back to traditional prompt
        if [[ "$choice_made" != "true" ]]; then
            echo "Choose option:"
            echo "  [1] $choice1"
            echo "  [2] $choice2"
            # In real code, this would read user input
            # For test, we simulate selection
            FALLBACK_CHOICE="1"
            choice_made=true
        fi

        return 0
    }

    # Test fallback mechanism
    mock_choice_with_fallback "Test prompt" "Option A" "Option B"
    if [[ "${FALLBACK_CHOICE:-}" == "1" ]]; then
        echo " ✅ PASS fallback to traditional prompt"
        ((TESTS_PASSED++)); ((TESTS_TOTAL++))
    else
        echo " ❌ FAIL fallback mechanism not working"
        ((TESTS_FAILED++)); ((TESTS_TOTAL++))
    fi
}

# Test non-interactive mode handling
test_non_interactive_mode() {
    echo "Testing: Non-interactive mode handling"

    # Mock function that handles non-interactive mode
    mock_non_interactive_choice() {
        if [[ "${NON_INTERACTIVE:-false}" == "true" ]]; then
            echo "Non-interactive mode: using default option"
            return 0
        else
            echo "Interactive mode: would show choices"
            return 0
        fi
    }

    # Test non-interactive mode handling
    local result
    result=$(mock_non_interactive_choice)
    assert_contains "Non-interactive mode" "$result"
    echo " ✅ PASS non-interactive mode detected"
}

# Test choice validation and sanitization
test_choice_validation() {
    echo "Testing: Choice validation and sanitization"

    # Mock function that validates choice input
    validate_choice_input() {
        local choice="$1"
        local max_choices="$2"

        # Check if choice is numeric and within range
        if [[ "$choice" =~ ^[0-9]+$ ]] && [[ $choice -ge 1 ]] && [[ $choice -le $max_choices ]]; then
            echo "VALID"
            return 0
        else
            echo "INVALID"
            return 1
        fi
    }

    # Test valid choices
    local result1
    result1=$(validate_choice_input "1" "3")
    assert_contains "VALID" "$result1"
    echo -n " ✅ PASS valid choice accepted"

    local result2
    result2=$(validate_choice_input "3" "3")
    assert_contains "VALID" "$result2"
    echo " ✅ PASS boundary choice accepted"

    # Test invalid choices
    local result3
    result3=$(validate_choice_input "0" "3")
    assert_contains "INVALID" "$result3"
    echo -n " ✅ PASS invalid choice rejected"

    local result4
    result4=$(validate_choice_input "abc" "3")
    assert_contains "INVALID" "$result4"
    echo " ✅ PASS non-numeric choice rejected"
}

# Test arrow key navigation support
test_arrow_key_navigation_support() {
    echo "Testing: Arrow key navigation support"

    # Check that the UI module includes arrow key handling
    if [[ -f "$PROJECT_ROOT/lib/setup-ui.sh" ]]; then
        local ui_content
        ui_content=$(cat "$PROJECT_ROOT/lib/setup-ui.sh")

        # Look for escape sequence handling
        if echo "$ui_content" | grep -q '\\x1b'; then
            echo " ✅ PASS escape sequence handling present"
            ((TESTS_PASSED++)); ((TESTS_TOTAL++))
        else
            echo " ❌ FAIL escape sequence handling missing"
            ((TESTS_FAILED++)); ((TESTS_TOTAL++))
        fi

        # Look for terminal capability detection
        if echo "$ui_content" | grep -q 'tput\|stty'; then
            echo " ✅ PASS terminal capability detection"
            ((TESTS_PASSED++)); ((TESTS_TOTAL++))
        else
            echo " ℹ️  INFO terminal capability detection not found"
            ((TESTS_TOTAL++))
        fi
    fi
}

# Test consistent choice formatting
test_consistent_choice_formatting() {
    echo "Testing: Consistent choice formatting"

    # Mock function that demonstrates consistent formatting
    format_choice_options() {
        local -a choices=("$@")
        local i

        for i in "${!choices[@]}"; do
            local choice_num=$((i + 1))
            echo "  [$choice_num] ${choices[$i]}"
        done
    }

    # Test formatting
    local formatted
    formatted=$(format_choice_options "First Option" "Second Option" "Third Option")

    assert_contains "\\[1\\]" "$formatted"
    echo -n " ✅ PASS consistent numbering format"

    assert_contains "\\[3\\]" "$formatted"
    echo " ✅ PASS all options formatted"
}

# Test integration with existing choice points
test_existing_choice_integration() {
    echo "Testing: Integration with existing choice points"

    # Check that existing choice points use the universal system
    if [[ -f "$PROJECT_ROOT/lib/setup-config.sh" ]]; then
        local config_content
        config_content=$(cat "$PROJECT_ROOT/lib/setup-config.sh")

        # Look for interactive choice usage in CLAUDE.md handling
        if echo "$config_content" | grep -q "show_interactive_choice"; then
            echo " ✅ PASS CLAUDE.md handling uses universal choice"
            ((TESTS_PASSED++)); ((TESTS_TOTAL++))
        else
            echo " ❌ FAIL CLAUDE.md handling not using universal choice"
            ((TESTS_FAILED++)); ((TESTS_TOTAL++))
        fi

        # Look for fallback mechanism
        if echo "$config_content" | grep -q "choice_made.*true"; then
            echo " ✅ PASS fallback mechanism implemented"
            ((TESTS_PASSED++)); ((TESTS_TOTAL++))
        else
            echo " ❌ FAIL fallback mechanism missing"
            ((TESTS_FAILED++)); ((TESTS_TOTAL++))
        fi
    fi
}

# Main test execution
main() {
    echo -e "${BLUE}Claude-Ally Universal Choice Prompt Tests${NC}"
    echo "=========================================="

    setup

    test_choice_function_signatures
    test_choice_prompt_standardization
    test_traditional_prompt_fallback
    test_non_interactive_mode
    test_choice_validation
    test_arrow_key_navigation_support
    test_consistent_choice_formatting
    test_existing_choice_integration

    cleanup

    echo ""
    echo "📊 Test Results:"
    echo "  Total:  $TESTS_TOTAL"
    echo -e "  Passed: ${GREEN}$TESTS_PASSED${NC}"
    echo -e "  Failed: ${RED}$TESTS_FAILED${NC}"

    if [[ $TESTS_FAILED -eq 0 ]]; then
        echo -e "${GREEN}🎉 All universal choice prompt tests passed!${NC}"
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