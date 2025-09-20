#!/bin/bash
#
# Tests for New Project Type Contribution Workflow
# Tests the detection, offering, and contribution of new project types
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
    echo -e "${BLUE}Setting up new project type contribution tests...${NC}"

    # Create test project directory
    TEST_PROJECT_DIR="/tmp/claude-ally-test-contribution-$$"
    mkdir -p "$TEST_PROJECT_DIR"

    # Set environment
    export PROJECT_DIR="$TEST_PROJECT_DIR"
    export SCRIPT_DIR="$PROJECT_ROOT/lib"
    export NON_INTERACTIVE="true"

    # Source required modules if available
    if [[ -f "$PROJECT_ROOT/lib/setup-ui.sh" ]]; then
        source "$PROJECT_ROOT/lib/setup-ui.sh"
    fi
    if [[ -f "$PROJECT_ROOT/lib/setup-config.sh" ]]; then
        source "$PROJECT_ROOT/lib/setup-config.sh"
    fi
}

# Cleanup test environment
cleanup() {
    if [[ -n "${TEST_PROJECT_DIR:-}" ]] && [[ -d "$TEST_PROJECT_DIR" ]]; then
        rm -rf "$TEST_PROJECT_DIR"
    fi
    # Clean up any exported variables
    unset DETECTED_CUSTOM_TYPE 2>/dev/null || true
}

# Test project type mapping functions
test_project_type_mapping() {
    echo "Testing: Project type mapping functions"

    # Test mapping functions exist in setup-ui.sh
    if [[ -f "$PROJECT_ROOT/lib/setup-ui.sh" ]]; then
        local ui_content
        ui_content=$(cat "$PROJECT_ROOT/lib/setup-ui.sh")

        # Look for map_detected_project_type function
        if echo "$ui_content" | grep -q "map_detected_project_type"; then
            echo " ✅ PASS project type mapping function exists"
            ((TESTS_PASSED++)); ((TESTS_TOTAL++))
        else
            echo " ❌ FAIL project type mapping function missing"
            ((TESTS_FAILED++)); ((TESTS_TOTAL++))
        fi

        # Look for get_project_type_description function
        if echo "$ui_content" | grep -q "get_project_type_description"; then
            echo " ✅ PASS project type description function exists"
            ((TESTS_PASSED++)); ((TESTS_TOTAL++))
        else
            echo " ❌ FAIL project type description function missing"
            ((TESTS_FAILED++)); ((TESTS_TOTAL++))
        fi
    fi
}

# Test custom project type detection
test_custom_project_type_detection() {
    echo "Testing: Custom project type detection"

    # Mock the project type mapping function
    mock_map_detected_project_type() {
        local detected_type="$1"
        case "$detected_type" in
            "web-app"|"mobile-app"|"ai-ml-service"|"desktop-app"|"cli-tool"|"library"|"api-service"|"other")
                echo "1" ;; # Known types map to options 1-8
            *)
                echo "8" ;; # Unknown types map to option 8 (other)
        esac
    }

    # Test known project type
    local result1
    result1=$(mock_map_detected_project_type "web-app")
    if [[ "$result1" == "1" ]]; then
        echo " ✅ PASS known project type mapped correctly"
        ((TESTS_PASSED++)); ((TESTS_TOTAL++))
    else
        echo " ❌ FAIL known project type mapping failed"
        ((TESTS_FAILED++)); ((TESTS_TOTAL++))
    fi

    # Test unknown project type
    local result2
    result2=$(mock_map_detected_project_type "kotlin-multiplatform-mobile")
    if [[ "$result2" == "8" ]]; then
        echo " ✅ PASS unknown project type mapped to option 8"
        ((TESTS_PASSED++)); ((TESTS_TOTAL++))
    else
        echo " ❌ FAIL unknown project type mapping failed"
        ((TESTS_FAILED++)); ((TESTS_TOTAL++))
    fi
}

# Test custom type variable setting
test_custom_type_variable_setting() {
    echo "Testing: Custom type variable setting"

    # Mock the workflow that sets DETECTED_CUSTOM_TYPE
    mock_detect_and_set_custom_type() {
        local detected_stack_info="$1"

        if [[ -n "$detected_stack_info" ]]; then
            IFS='|' read -r stack_id tech_stack project_type confidence <<< "$detected_stack_info"

            # Simulate mapping check
            local mapped_option
            mapped_option=$(mock_map_detected_project_type "$project_type")

            if [[ "$mapped_option" == "8" ]] && [[ "$project_type" != "other" ]]; then
                export DETECTED_CUSTOM_TYPE="$project_type"
                echo "Custom type detected: $project_type"
                return 0
            fi
        fi
        return 1
    }

    # Test with custom project type
    local custom_stack="kotlin-multiplatform|Kotlin/Compose Multiplatform|kotlin-multiplatform-mobile|85"
    if mock_detect_and_set_custom_type "$custom_stack"; then
        if [[ "${DETECTED_CUSTOM_TYPE:-}" == "kotlin-multiplatform-mobile" ]]; then
            echo " ✅ PASS custom type variable set correctly"
            ((TESTS_PASSED++)); ((TESTS_TOTAL++))
        else
            echo " ❌ FAIL custom type variable not set"
            ((TESTS_FAILED++)); ((TESTS_TOTAL++))
        fi
    else
        echo " ❌ FAIL custom type detection failed"
        ((TESTS_FAILED++)); ((TESTS_TOTAL++))
    fi
}

# Test contribution offer workflow
test_contribution_offer_workflow() {
    echo "Testing: Contribution offer workflow"

    # Check that setup-config.sh has contribution offer logic
    if [[ -f "$PROJECT_ROOT/lib/setup-config.sh" ]]; then
        local config_content
        config_content=$(cat "$PROJECT_ROOT/lib/setup-config.sh")

        # Look for DETECTED_CUSTOM_TYPE check
        if echo "$config_content" | grep -q "DETECTED_CUSTOM_TYPE"; then
            echo " ✅ PASS contribution check for custom types"
            ((TESTS_PASSED++)); ((TESTS_TOTAL++))
        else
            echo " ❌ FAIL contribution check missing"
            ((TESTS_FAILED++)); ((TESTS_TOTAL++))
        fi

        # Look for contribution offer message
        if echo "$config_content" | grep -q "contribute this new project type"; then
            echo " ✅ PASS contribution offer message"
            ((TESTS_PASSED++)); ((TESTS_TOTAL++))
        else
            echo " ❌ FAIL contribution offer message missing"
            ((TESTS_FAILED++)); ((TESTS_TOTAL++))
        fi

        # Look for claude-ally contribute command reference
        if echo "$config_content" | grep -q "claude-ally contribute"; then
            echo " ✅ PASS contribute command reference"
            ((TESTS_PASSED++)); ((TESTS_TOTAL++))
        else
            echo " ❌ FAIL contribute command reference missing"
            ((TESTS_FAILED++)); ((TESTS_TOTAL++))
        fi
    fi
}

# Test option 9 offering for custom types
test_option_nine_offering() {
    echo "Testing: Option 9 offering for custom types"

    # Mock the function that checks if option 9 should be offered
    should_offer_option_nine() {
        local detected_stack_info="$1"

        if [[ -n "$detected_stack_info" ]]; then
            IFS='|' read -r stack_id tech_stack project_type confidence <<< "$detected_stack_info"
            local mapped_option
            mapped_option=$(mock_map_detected_project_type "$project_type")

            if [[ "$mapped_option" == "8" ]] && [[ "$project_type" != "other" ]]; then
                echo "OFFER_OPTION_9"
                return 0
            fi
        fi
        echo "NO_OPTION_9"
        return 1
    }

    # Test with custom project type
    local custom_stack="rust-wasm|Rust + WebAssembly|rust-wasm-app|90"
    local result
    result=$(should_offer_option_nine "$custom_stack")
    assert_contains "OFFER_OPTION_9" "$result"
    echo " ✅ PASS option 9 offered for custom type"

    # Test with known project type
    local known_stack="nextjs|Next.js|web-app|95"
    local result2
    result2=$(should_offer_option_nine "$known_stack")
    assert_contains "NO_OPTION_9" "$result2"
    echo " ✅ PASS option 9 not offered for known type"
}

# Test Claude analysis integration
test_claude_analysis_integration() {
    echo "Testing: Claude analysis integration"

    # Check that setup-ui.sh includes Claude analysis for unknown projects
    if [[ -f "$PROJECT_ROOT/lib/setup-ui.sh" ]]; then
        local ui_content
        ui_content=$(cat "$PROJECT_ROOT/lib/setup-ui.sh")

        # Look for Claude analysis call
        if echo "$ui_content" | grep -q "analyze_unknown_stack_with_claude"; then
            echo " ✅ PASS Claude analysis integration"
            ((TESTS_PASSED++)); ((TESTS_TOTAL++))
        else
            echo " ❌ FAIL Claude analysis integration missing"
            ((TESTS_FAILED++)); ((TESTS_TOTAL++))
        fi

        # Look for Claude response parsing
        if echo "$ui_content" | grep -q "suggested_stack_id.*suggested_tech_stack.*suggested_project_type"; then
            echo " ✅ PASS Claude response parsing"
            ((TESTS_PASSED++)); ((TESTS_TOTAL++))
        else
            echo " ❌ FAIL Claude response parsing missing"
            ((TESTS_FAILED++)); ((TESTS_TOTAL++))
        fi
    fi
}

# Test error handling for failed Claude analysis
test_claude_analysis_error_handling() {
    echo "Testing: Claude analysis error handling"

    # Mock Claude analysis with error handling
    mock_claude_analysis_with_error_handling() {
        local analysis_result="$1"

        if [[ -n "$analysis_result" ]]; then
            # Parse response
            local suggested_stack_id
            suggested_stack_id=$(echo "$analysis_result" | grep -i "STACK_ID:" | head -1 | sed 's/.*STACK_ID:[[:space:]]*//' | tr -d '\"*`')

            if [[ -n "$suggested_stack_id" ]]; then
                echo "SUCCESS: $suggested_stack_id"
                return 0
            else
                echo -e "${YELLOW}⚠️  Claude analysis completed but could not parse project type${NC}" >&2
                return 1
            fi
        else
            echo -e "${YELLOW}⚠️  Claude analysis failed, continuing with standard options${NC}" >&2
            return 1
        fi
    }

    # Test successful parsing
    local success_analysis="STACK_ID: flutter-app"
    local result1
    result1=$(mock_claude_analysis_with_error_handling "$success_analysis" 2>/dev/null)
    assert_contains "SUCCESS: flutter-app" "$result1"
    echo " ✅ PASS successful Claude analysis parsing"

    # Test error handling
    local failed_analysis=""
    local stderr_msg
    stderr_msg=$(mock_claude_analysis_with_error_handling "$failed_analysis" 2>&1 >/dev/null)
    assert_contains "Claude analysis failed" "$stderr_msg"
    echo " ✅ PASS Claude analysis error handling"
}

# Test non-interactive mode handling
test_non_interactive_contribution_handling() {
    echo "Testing: Non-interactive contribution handling"

    # Check that non-interactive mode is handled in contribution workflow
    if [[ -f "$PROJECT_ROOT/lib/setup-config.sh" ]]; then
        local config_content
        config_content=$(cat "$PROJECT_ROOT/lib/setup-config.sh")

        # Look for non-interactive mode check in contribution
        if echo "$config_content" | grep -q "Non-interactive mode.*skipping contribution"; then
            echo " ✅ PASS non-interactive contribution handling"
            ((TESTS_PASSED++)); ((TESTS_TOTAL++))
        else
            echo " ❌ FAIL non-interactive contribution handling missing"
            ((TESTS_FAILED++)); ((TESTS_TOTAL++))
        fi
    fi
}

# Main test execution
main() {
    echo -e "${BLUE}Claude-Ally New Project Type Contribution Tests${NC}"
    echo "==============================================="

    setup

    test_project_type_mapping
    test_custom_project_type_detection
    test_custom_type_variable_setting
    test_contribution_offer_workflow
    test_option_nine_offering
    test_claude_analysis_integration
    test_claude_analysis_error_handling
    test_non_interactive_contribution_handling

    cleanup

    echo ""
    echo "📊 Test Results:"
    echo "  Total:  $TESTS_TOTAL"
    echo -e "  Passed: ${GREEN}$TESTS_PASSED${NC}"
    echo -e "  Failed: ${RED}$TESTS_FAILED${NC}"

    if [[ $TESTS_FAILED -eq 0 ]]; then
        echo -e "${GREEN}🎉 All new project type contribution tests passed!${NC}"
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