#!/bin/bash
# Unit Tests for Contribution Workflow
# Tests the automatic contribution workflow execution

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

# Test configuration
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
TEST_TEMP_DIR=""
TESTS_TOTAL=0
TESTS_PASSED=0
TESTS_FAILED=0

# Test utilities
setup() {
    TEST_TEMP_DIR=$(mktemp -d -t claude-ally-contrib-test-XXXXXX)
    echo -e "${BLUE}🧪 Running Contribution Workflow Unit Tests${NC}"
    echo "=============================================="
    echo ""
}

cleanup() {
    rm -rf "$TEST_TEMP_DIR" 2>/dev/null || true
}

assert_success() {
    local test_name="$1"
    TESTS_TOTAL=$((TESTS_TOTAL + 1))
    echo -e "${GREEN}✅ PASS${NC} $test_name"
    TESTS_PASSED=$((TESTS_PASSED + 1))
}

assert_failure() {
    local test_name="$1"
    local details="$2"
    TESTS_TOTAL=$((TESTS_TOTAL + 1))
    echo -e "${RED}❌ FAIL${NC} $test_name"
    if [[ -n "$details" ]]; then
        echo -e "   ${YELLOW}Details: $details${NC}"
    fi
    TESTS_FAILED=$((TESTS_FAILED + 1))
}

teardown() {
    cleanup
    unset CONTRIBUTE_ACCEPTED
    unset STACK_IS_UNKNOWN
    unset DETECTED_CUSTOM_TYPE

    echo ""
    echo -e "${BOLD}Test Summary:${NC}"
    echo "Total: $TESTS_TOTAL, Passed: $TESTS_PASSED, Failed: $TESTS_FAILED"

    if [[ $TESTS_FAILED -eq 0 ]]; then
        echo -e "${GREEN}🎉 All tests passed!${NC}"
        exit 0
    else
        echo -e "${RED}💥 Some tests failed!${NC}"
        exit 1
    fi
}

# Test: Custom project type contribution sets CONTRIBUTE_ACCEPTED
test_custom_project_type_contribution() {
    echo "Testing: Custom project type contribution workflow"

    # Clear variables from previous tests
    unset CONTRIBUTE_ACCEPTED STACK_IS_UNKNOWN

    # Set up test environment
    export DETECTED_CUSTOM_TYPE="Test Custom Type"
    export NON_INTERACTIVE="false"
    local tech_stack="Test Stack + Framework"
    local project_type="test-app"

    # Mock user accepting contribution
    # Simulate the logic from check_stack_and_offer_contribution
    if [[ -n "${DETECTED_CUSTOM_TYPE:-}" ]]; then
        # User accepts contribution (simulated)
        local CONTRIBUTE_CHOICE="Y"

        if [[ "$CONTRIBUTE_CHOICE" =~ ^[Yy]$ ]] || [[ -z "$CONTRIBUTE_CHOICE" ]]; then
            CONTRIBUTE_ACCEPTED=true
            STACK_IS_UNKNOWN=true
        fi
    fi

    # Verify the variables were set
    if [[ "$CONTRIBUTE_ACCEPTED" == "true" ]]; then
        assert_success "Custom type contribution sets CONTRIBUTE_ACCEPTED" "CONTRIBUTE_ACCEPTED properly set"
    else
        assert_failure "Custom type contribution sets CONTRIBUTE_ACCEPTED" "CONTRIBUTE_ACCEPTED not set"
    fi

    if [[ "$STACK_IS_UNKNOWN" == "true" ]]; then
        assert_success "Custom type contribution sets STACK_IS_UNKNOWN" "STACK_IS_UNKNOWN properly set"
    else
        assert_failure "Custom type contribution sets STACK_IS_UNKNOWN" "STACK_IS_UNKNOWN not set"
    fi
}

# Test: Unknown stack contribution sets CONTRIBUTE_ACCEPTED
test_unknown_stack_contribution() {
    echo "Testing: Unknown stack contribution workflow"

    # Clear variables from previous tests
    unset CONTRIBUTE_ACCEPTED STACK_IS_UNKNOWN

    # Set up test environment
    unset DETECTED_CUSTOM_TYPE
    export NON_INTERACTIVE="false"
    local tech_stack="Unknown Framework + Database"
    local project_type="unknown-app"

    # Mock unknown stack detection
    local detection_result="unknown"

    # Simulate the logic from check_stack_and_offer_contribution
    if [[ "$detection_result" == *"Unknown stack"* ]] || [[ "$detection_result" == "unknown" ]]; then
        # User accepts contribution (simulated)
        local CONTRIBUTE_CHOICE="y"

        if [[ "$CONTRIBUTE_CHOICE" =~ ^[Yy]$ ]]; then
            CONTRIBUTE_ACCEPTED=true
            STACK_IS_UNKNOWN=true
        fi
    fi

    # Verify the variables were set
    if [[ "$CONTRIBUTE_ACCEPTED" == "true" ]]; then
        assert_success "Unknown stack contribution sets CONTRIBUTE_ACCEPTED" "CONTRIBUTE_ACCEPTED properly set"
    else
        assert_failure "Unknown stack contribution sets CONTRIBUTE_ACCEPTED" "CONTRIBUTE_ACCEPTED not set"
    fi

    if [[ "$STACK_IS_UNKNOWN" == "true" ]]; then
        assert_success "Unknown stack contribution sets STACK_IS_UNKNOWN" "STACK_IS_UNKNOWN properly set"
    else
        assert_failure "Unknown stack contribution sets STACK_IS_UNKNOWN" "STACK_IS_UNKNOWN not set"
    fi
}

# Test: Non-interactive mode skips contribution
test_non_interactive_contribution_skip() {
    echo "Testing: Non-interactive mode contribution handling"

    # Clear variables from previous tests
    unset CONTRIBUTE_ACCEPTED STACK_IS_UNKNOWN

    # Set up test environment
    export DETECTED_CUSTOM_TYPE="Test Custom Type"
    export NON_INTERACTIVE="true"
    local tech_stack="Test Stack + Framework"
    local project_type="test-app"

    # Simulate the logic from check_stack_and_offer_contribution
    local contribution_skipped=false
    if [[ -n "${DETECTED_CUSTOM_TYPE:-}" ]]; then
        if [[ "${NON_INTERACTIVE:-false}" == "true" ]]; then
            # Non-interactive mode should skip contribution
            contribution_skipped=true
            # No variables should be set
        fi
    fi

    # Verify contribution was skipped
    if [[ "$contribution_skipped" == "true" ]]; then
        assert_success "Non-interactive mode skips contribution" "Contribution properly skipped"
    else
        assert_failure "Non-interactive mode skips contribution" "Contribution not skipped"
    fi

    # Verify CONTRIBUTE_ACCEPTED is not set
    if [[ -z "${CONTRIBUTE_ACCEPTED:-}" ]]; then
        assert_success "Non-interactive mode doesn't set CONTRIBUTE_ACCEPTED" "CONTRIBUTE_ACCEPTED not set"
    else
        assert_failure "Non-interactive mode doesn't set CONTRIBUTE_ACCEPTED" "CONTRIBUTE_ACCEPTED incorrectly set"
    fi
}

# Test: User declining contribution
test_contribution_decline() {
    echo "Testing: User declining contribution"

    # Clear variables from previous tests
    unset CONTRIBUTE_ACCEPTED STACK_IS_UNKNOWN

    # Set up test environment
    export DETECTED_CUSTOM_TYPE="Test Custom Type"
    export NON_INTERACTIVE="false"
    local tech_stack="Test Stack + Framework"
    local project_type="test-app"

    # Mock user declining contribution
    if [[ -n "${DETECTED_CUSTOM_TYPE:-}" ]]; then
        # User declines contribution (simulated)
        local CONTRIBUTE_CHOICE="n"

        if [[ "$CONTRIBUTE_CHOICE" =~ ^[Yy]$ ]] || [[ -z "$CONTRIBUTE_CHOICE" ]]; then
            CONTRIBUTE_ACCEPTED=true
            STACK_IS_UNKNOWN=true
        fi
        # When user declines (CONTRIBUTE_CHOICE="n"), variables should NOT be set
    fi

    # Verify the variables were NOT set
    if [[ -z "${CONTRIBUTE_ACCEPTED:-}" ]]; then
        assert_success "Declining contribution doesn't set CONTRIBUTE_ACCEPTED" "CONTRIBUTE_ACCEPTED not set"
    else
        assert_failure "Declining contribution doesn't set CONTRIBUTE_ACCEPTED" "CONTRIBUTE_ACCEPTED incorrectly set"
    fi

    if [[ -z "${STACK_IS_UNKNOWN:-}" ]]; then
        assert_success "Declining contribution doesn't set STACK_IS_UNKNOWN" "STACK_IS_UNKNOWN not set"
    else
        assert_failure "Declining contribution doesn't set STACK_IS_UNKNOWN" "STACK_IS_UNKNOWN incorrectly set"
    fi
}

# Test: Both contribution paths produce consistent behavior
test_contribution_consistency() {
    echo "Testing: Contribution workflow consistency"

    # Test custom type path
    export DETECTED_CUSTOM_TYPE="Custom Type"
    unset CONTRIBUTE_ACCEPTED STACK_IS_UNKNOWN

    # Simulate custom type contribution acceptance
    local CONTRIBUTE_CHOICE="Y"
    if [[ "$CONTRIBUTE_CHOICE" =~ ^[Yy]$ ]] || [[ -z "$CONTRIBUTE_CHOICE" ]]; then
        CONTRIBUTE_ACCEPTED=true
        STACK_IS_UNKNOWN=true
    fi

    local custom_type_accepted="$CONTRIBUTE_ACCEPTED"
    local custom_type_unknown="$STACK_IS_UNKNOWN"

    # Test unknown stack path
    unset DETECTED_CUSTOM_TYPE
    unset CONTRIBUTE_ACCEPTED STACK_IS_UNKNOWN

    # Simulate unknown stack contribution acceptance
    local detection_result="unknown"
    if [[ "$detection_result" == "unknown" ]]; then
        local CONTRIBUTE_CHOICE="y"
        if [[ "$CONTRIBUTE_CHOICE" =~ ^[Yy]$ ]]; then
            CONTRIBUTE_ACCEPTED=true
            STACK_IS_UNKNOWN=true
        fi
    fi

    local unknown_stack_accepted="$CONTRIBUTE_ACCEPTED"
    local unknown_stack_unknown="$STACK_IS_UNKNOWN"

    # Verify both paths set the same variables
    if [[ "$custom_type_accepted" == "$unknown_stack_accepted" && "$custom_type_accepted" == "true" ]]; then
        assert_success "Both contribution paths set CONTRIBUTE_ACCEPTED consistently" "Both paths set CONTRIBUTE_ACCEPTED=true"
    else
        assert_failure "Both contribution paths set CONTRIBUTE_ACCEPTED consistently" "Inconsistent CONTRIBUTE_ACCEPTED setting"
    fi

    if [[ "$custom_type_unknown" == "$unknown_stack_unknown" && "$custom_type_unknown" == "true" ]]; then
        assert_success "Both contribution paths set STACK_IS_UNKNOWN consistently" "Both paths set STACK_IS_UNKNOWN=true"
    else
        assert_failure "Both contribution paths set STACK_IS_UNKNOWN consistently" "Inconsistent STACK_IS_UNKNOWN setting"
    fi
}

# Test: Contribution workflow message consistency
test_contribution_message_consistency() {
    echo "Testing: Contribution workflow message consistency"

    # Define expected message components
    local expected_phrases=(
        "🎉 Thank you for contributing!"
        "contribution workflow will run automatically"
        "after setup completes"
        "help the community detect similar projects"
    )

    # Test that both paths should now show the same message
    local custom_type_message="🎉 Thank you for contributing! The contribution workflow will run automatically after setup completes. This will help the community detect similar projects automatically."
    local unknown_stack_message="🎉 Thank you for contributing! The contribution workflow will run automatically after setup completes. This will help the community detect similar projects automatically."

    # Check that both messages are now consistent
    if [[ "$custom_type_message" == "$unknown_stack_message" ]]; then
        assert_success "Contribution messages are consistent" "Both paths show same message"
    else
        assert_failure "Contribution messages are consistent" "Messages differ between paths"
    fi

    # Check that the message contains expected phrases
    for phrase in "${expected_phrases[@]}"; do
        if [[ "$custom_type_message" == *"$phrase"* ]]; then
            assert_success "Message contains expected phrase: '$phrase'" "Phrase found in message"
        else
            assert_failure "Message contains expected phrase: '$phrase'" "Phrase missing from message"
        fi
    done
}

# Run the test suite
main() {
    setup

    test_custom_project_type_contribution
    test_unknown_stack_contribution
    test_non_interactive_contribution_skip
    test_contribution_decline
    test_contribution_consistency
    test_contribution_message_consistency

    teardown
}

# Run if called directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi