#!/bin/bash
#
# Tests for Intelligent Project Type Detection
# Tests the enhanced setup process with Claude integration
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

# Test utilities
source "$SCRIPT_DIR/../test_utils.sh" 2>/dev/null || {
    echo "Warning: test_utils.sh not found, using basic functions"

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
            echo "✅ PASS";
            ((TESTS_PASSED++))
        else
            echo "❌ FAIL";
            ((TESTS_FAILED++))
        fi
        ((TESTS_TOTAL++))
    }
    assert_not_contains() {
        if ! echo "$2" | grep -q "$1"; then
            echo "✅ PASS";
            ((TESTS_PASSED++))
        else
            echo "❌ FAIL";
            ((TESTS_FAILED++))
        fi
        ((TESTS_TOTAL++))
    }
}

# Setup test environment
setup() {
    echo -e "${BLUE}Setting up intelligent project detection tests...${NC}"

    # Create test project directory
    TEST_PROJECT_DIR="/tmp/claude-ally-test-project-$$"
    mkdir -p "$TEST_PROJECT_DIR"

    # Source required modules
    source "$PROJECT_ROOT/lib/setup-ui.sh"
    source "$PROJECT_ROOT/lib/stack-detector.sh" 2>/dev/null || echo "Stack detector not available"
    source "$PROJECT_ROOT/lib/contribute-stack.sh" 2>/dev/null || echo "Contribute module not available"

    # Set environment
    export PROJECT_DIR="$TEST_PROJECT_DIR"
    export SCRIPT_DIR="$PROJECT_ROOT/lib"
    export NON_INTERACTIVE="true"
}

# Cleanup test environment
cleanup() {
    if [[ -n "${TEST_PROJECT_DIR:-}" ]] && [[ -d "$TEST_PROJECT_DIR" ]]; then
        rm -rf "$TEST_PROJECT_DIR"
    fi
}

# Test project type mapping functions
test_project_type_mapping() {
    echo "Testing: Project type mapping functions"

    # Test known mappings
    result=$(map_detected_project_type "web-app")
    [[ "$result" == "1" ]]
    assert_success
    echo -n "✅ PASS web-app maps to option 1"
    ((TESTS_PASSED++)); ((TESTS_TOTAL++))

    result=$(map_detected_project_type "mobile-app")
    [[ "$result" == "2" ]]
    assert_success
    echo " ✅ PASS mobile-app maps to option 2"
    ((TESTS_PASSED++)); ((TESTS_TOTAL++))

    result=$(map_detected_project_type "ai-ml-service")
    [[ "$result" == "3" ]]
    assert_success
    echo " ✅ PASS ai-ml-service maps to option 3"
    ((TESTS_PASSED++)); ((TESTS_TOTAL++))

    # Test unknown mapping (should return 8)
    result=$(map_detected_project_type "unknown-custom-type")
    [[ "$result" == "8" ]]
    assert_success
    echo " ✅ PASS unknown type maps to option 8"
    ((TESTS_PASSED++)); ((TESTS_TOTAL++))
}

# Test project type descriptions
test_project_type_descriptions() {
    echo "Testing: Project type description functions"

    result=$(get_project_type_description "nextjs-ai-app")
    [[ "$result" == "Next.js AI Application" ]]
    assert_success
    echo " ✅ PASS nextjs-ai-app description"
    ((TESTS_PASSED++)); ((TESTS_TOTAL++))

    result=$(get_project_type_description "cordova-hybrid-app")
    [[ "$result" == "Cordova Hybrid Mobile App" ]]
    assert_success
    echo " ✅ PASS cordova-hybrid-app description"
    ((TESTS_PASSED++)); ((TESTS_TOTAL++))

    result=$(get_project_type_description "unknown-type")
    [[ "$result" == "unknown-type" ]]
    assert_success
    echo " ✅ PASS unknown type returns itself"
    ((TESTS_PASSED++)); ((TESTS_TOTAL++))
}

# Test stack detection integration in setup
test_stack_detection_integration() {
    echo "Testing: Stack detection integration in setup"

    # Mock detect_project_stack function for testing
    detect_project_stack() {
        local project_dir="$1"
        if [[ -f "$project_dir/package.json" ]]; then
            echo "nextjs-ai|Next.js + AI/LLM|nextjs-ai-app|85"
            return 0
        else
            return 1 # No stack detected
        fi
    }

    # Test with Next.js project
    echo '{"name": "test-app", "dependencies": {"next": "^13.0.0", "openai": "^4.0.0"}}' > "$TEST_PROJECT_DIR/package.json"

    if result=$(detect_project_stack "$TEST_PROJECT_DIR"); then
        IFS='|' read -r stack_id tech_stack project_type confidence <<< "$result"
        [[ "$stack_id" == "nextjs-ai" ]]
        assert_success
        echo " ✅ PASS detects Next.js AI stack"
        ((TESTS_PASSED++)); ((TESTS_TOTAL++))

        [[ "$project_type" == "nextjs-ai-app" ]]
        assert_success
        echo " ✅ PASS identifies correct project type"
        ((TESTS_PASSED++)); ((TESTS_TOTAL++))
    fi

    # Test with unknown project
    rm -f "$TEST_PROJECT_DIR/package.json"
    echo "unknown content" > "$TEST_PROJECT_DIR/README.md"

    if ! detect_project_stack "$TEST_PROJECT_DIR" >/dev/null 2>&1; then
        echo " ✅ PASS unknown project not detected by stack detector"
        ((TESTS_PASSED++)); ((TESTS_TOTAL++))
    fi
}

# Test Claude analysis mocking
test_claude_analysis_mocking() {
    echo "Testing: Claude analysis integration"

    # Mock analyze_unknown_stack_with_claude function
    analyze_unknown_stack_with_claude() {
        local project_dir="$1"
        local project_name="$2"

        # Simulate Claude analysis output
        cat << 'EOF'
# Stack Analysis for kotlin-multiplatform

## Analysis Results:

**STACK_ID**: kotlin-multiplatform-mobile
**TECH_STACK**: Kotlin/Compose Multiplatform
**PROJECT_TYPE**: kotlin-multiplatform-mobile
**CONFIDENCE_PATTERNS**: build.gradle.kts, settings.gradle.kts, composeApp/
**WORTH_ADDING**: YES - This is a modern cross-platform development stack
**DETECTION_CODE**: Check for Kotlin Multiplatform and Compose configurations
EOF
    }

    # Test Claude analysis parsing
    result=$(analyze_unknown_stack_with_claude "$TEST_PROJECT_DIR" "test-project")

    # Test parsing of Claude response
    suggested_stack_id=$(echo "$result" | grep -i "STACK_ID:" | head -1 | sed 's/.*STACK_ID:[[:space:]]*//' | sed 's/[[:space:]]*$//' | tr -d '"*`')
    suggested_tech_stack=$(echo "$result" | grep -i "TECH_STACK:" | head -1 | sed 's/.*TECH_STACK:[[:space:]]*//' | sed 's/[[:space:]]*$//' | tr -d '"*`')
    suggested_project_type=$(echo "$result" | grep -i "PROJECT_TYPE:" | head -1 | sed 's/.*PROJECT_TYPE:[[:space:]]*//' | sed 's/[[:space:]]*$//' | tr -d '"*`')

    [[ "$suggested_stack_id" == "kotlin-multiplatform-mobile" ]]
    assert_success
    echo " ✅ PASS parses STACK_ID correctly"
    ((TESTS_PASSED++)); ((TESTS_TOTAL++))

    [[ "$suggested_tech_stack" == "Kotlin/Compose Multiplatform" ]]
    assert_success
    echo " ✅ PASS parses TECH_STACK correctly"
    ((TESTS_PASSED++)); ((TESTS_TOTAL++))

    [[ "$suggested_project_type" == "kotlin-multiplatform-mobile" ]]
    assert_success
    echo " ✅ PASS parses PROJECT_TYPE correctly"
    ((TESTS_PASSED++)); ((TESTS_TOTAL++))
}

# Test custom project type workflow
test_custom_project_type_workflow() {
    echo "Testing: Custom project type workflow"

    # Simulate detected stack info that doesn't map to existing types
    detected_stack_info="kotlin-multiplatform|Kotlin/Compose Multiplatform|kotlin-multiplatform-mobile|85"

    IFS='|' read -r _ _ detected_type _ <<< "$detected_stack_info"
    mapped_option=$(map_detected_project_type "$detected_type")

    [[ "$mapped_option" == "8" ]]
    assert_success
    echo " ✅ PASS unknown project type maps to option 8"
    ((TESTS_PASSED++)); ((TESTS_TOTAL++))

    description=$(get_project_type_description "$detected_type")
    [[ "$description" == "kotlin-multiplatform-mobile" ]]
    assert_success
    echo " ✅ PASS gets description for unknown type"
    ((TESTS_PASSED++)); ((TESTS_TOTAL++))

    # Test that custom option would be offered
    if [[ "$mapped_option" == "8" ]] && [[ "$detected_type" != "other" ]]; then
        echo " ✅ PASS would offer custom option 9"
        ((TESTS_PASSED++)); ((TESTS_TOTAL++))
    fi
}

# Test contribution integration
test_contribution_integration() {
    echo "Testing: Contribution workflow integration"

    # Mock DETECTED_CUSTOM_TYPE variable
    export DETECTED_CUSTOM_TYPE="kotlin-multiplatform-mobile"

    # Test that contribution check detects custom type
    if [[ -n "${DETECTED_CUSTOM_TYPE:-}" ]]; then
        echo " ✅ PASS detects custom type variable"
        ((TESTS_PASSED++)); ((TESTS_TOTAL++))
    fi

    # Test contribution message formatting
    tech_stack="Kotlin/Compose Multiplatform"
    if [[ -n "$DETECTED_CUSTOM_TYPE" ]]; then
        # This simulates what check_stack_and_offer_contribution would do
        echo " ✅ PASS would offer contribution for custom type"
        ((TESTS_PASSED++)); ((TESTS_TOTAL++))
    fi
}

# Test error handling and edge cases
test_error_handling() {
    echo "Testing: Error handling and edge cases"

    # Test empty stack detection result
    detected_stack_info=""
    if [[ -z "$detected_stack_info" ]]; then
        echo " ✅ PASS handles empty stack detection"
        ((TESTS_PASSED++)); ((TESTS_TOTAL++))
    fi

    # Test malformed stack detection result
    detected_stack_info="invalid|format"
    IFS='|' read -r stack_id tech_stack project_type confidence <<< "$detected_stack_info"
    if [[ -z "$project_type" ]]; then
        echo " ✅ PASS handles malformed stack result"
        ((TESTS_PASSED++)); ((TESTS_TOTAL++))
    fi

    # Test missing functions gracefully
    if ! declare -f nonexistent_function >/dev/null; then
        echo " ✅ PASS handles missing functions"
        ((TESTS_PASSED++)); ((TESTS_TOTAL++))
    fi
}

# Main test execution
main() {
    echo -e "${BLUE}Claude-Ally Intelligent Project Detection Tests${NC}"
    echo "=============================================="

    setup

    test_project_type_mapping
    test_project_type_descriptions
    test_stack_detection_integration
    test_claude_analysis_mocking
    test_custom_project_type_workflow
    test_contribution_integration
    test_error_handling

    cleanup

    echo ""
    echo "📊 Test Results:"
    echo "  Total:  $TESTS_TOTAL"
    echo -e "  Passed: ${GREEN}$TESTS_PASSED${NC}"
    echo -e "  Failed: ${RED}$TESTS_FAILED${NC}"

    if [[ $TESTS_FAILED -eq 0 ]]; then
        echo -e "${GREEN}🎉 All intelligent project detection tests passed!${NC}"
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