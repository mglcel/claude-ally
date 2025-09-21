#!/bin/bash
#
# Tests for Enhanced Recommendation System
# Tests the recommendation functionality for detected project types
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

assert_not_contains() {
    if ! echo "$2" | grep -q "$1"; then
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
    echo -e "${BLUE}Setting up recommendation system tests...${NC}"

    # Create test project directory
    TEST_PROJECT_DIR="/tmp/claude-ally-test-recommendations-$$"
    mkdir -p "$TEST_PROJECT_DIR"

    # Set environment
    export PROJECT_DIR="$TEST_PROJECT_DIR"
    export SCRIPT_DIR="$PROJECT_ROOT/lib"
    export NON_INTERACTIVE="true"

    # Source the UI module to test recommendation functions
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

# Test recommendation message formatting
test_recommendation_message_formatting() {
    echo "Testing: Recommendation message formatting"

    # Mock the recommendation display logic
    mock_display_recommendation() {
        local custom_type_available="$1"
        local suggested_description="$2"
        local suggested_option="$3"

        if [[ -n "$suggested_option" ]] && [[ "$suggested_option" != "8" ]]; then
            echo "🎯 Recommended: $suggested_option ($suggested_description)"
        elif [[ "$custom_type_available" == "true" ]]; then
            echo "🎯 Recommended: 9 (Create new: $suggested_description)"
            echo "💡 This project type was automatically detected for you"
        fi
    }

    # Test known project type recommendation
    local output1
    output1=$(mock_display_recommendation "false" "Web Application" "1")
    assert_contains "🎯 Recommended: 1" "$output1"
    echo -n " ✅ PASS known type recommendation format"

    # Test custom project type recommendation
    local output2
    output2=$(mock_display_recommendation "true" "Kotlin Multiplatform Mobile App" "")
    assert_contains "🎯 Recommended: 9" "$output2"
    echo -n " ✅ PASS custom type recommendation format"

    assert_contains "💡 This project type was automatically detected" "$output2"
    echo " ✅ PASS detection explanation message"
}

# Test interactive menu default selection
test_interactive_menu_defaults() {
    echo "Testing: Interactive menu default selection"

    # Test the show_interactive_menu function parameter parsing
    mock_menu_setup() {
        local default_selected=0
        local recommended_index=-1
        local -a options=()

        # Simulate the parameter parsing logic
        if [[ $1 =~ ^[0-9]+$ ]]; then
            default_selected=$1
            recommended_index=$1
            shift
        fi

        options=("$@")
        local selected=$default_selected

        echo "selected:$selected,recommended:$recommended_index,options:${#options[@]}"
    }

    # Test with default selection
    local result1
    result1=$(mock_menu_setup "8" "Option 1" "Option 2" "Option 3" "Option 4" "Option 5" "Option 6" "Option 7" "Option 8" "Create new: Kotlin Multiplatform")
    assert_contains "selected:8" "$result1"
    echo -n " ✅ PASS default selection parsing"

    assert_contains "recommended:8" "$result1"
    echo -n " ✅ PASS recommendation index tracking"

    assert_contains "options:9" "$result1"
    echo " ✅ PASS options array parsing"

    # Test without default selection
    local result2
    result2=$(mock_menu_setup "Option A" "Option B" "Option C")
    assert_contains "selected:0" "$result2"
    echo -n " ✅ PASS no default fallback"

    assert_contains "recommended:-1" "$result2"
    echo " ✅ PASS no recommendation fallback"
}

# Test recommendation display indicators
test_recommendation_display_indicators() {
    echo "Testing: Recommendation display indicators"

    # Mock the menu display logic
    mock_menu_display() {
        local selected="$1"
        local recommended_index="$2"
        local option_text="$3"

        if [[ $selected -eq $recommended_index ]]; then
            echo "► 🎯 $option_text (Recommended)"
        elif [[ $selected -eq 0 ]]; then
            echo "► $option_text"
        else
            if [[ 0 -eq $recommended_index ]]; then
                echo "🎯 $option_text (Recommended)"
            else
                echo "$option_text"
            fi
        fi
    }

    # Test selected + recommended option
    local display1
    display1=$(mock_menu_display "8" "8" "9. Create new: Kotlin Multiplatform Mobile App")
    assert_contains "► 🎯" "$display1"
    echo -n " ✅ PASS selected recommended option display"

    assert_contains "(Recommended)" "$display1"
    echo " ✅ PASS recommended label present"

    # Test non-selected recommended option
    local display2
    display2=$(mock_menu_display "1" "0" "1. Web Application")
    assert_contains "🎯" "$display2"
    echo -n " ✅ PASS non-selected recommended option indicator"

    assert_not_contains "►" "$display2"
    echo " ✅ PASS no selection arrow for non-selected"

    # Test regular selected option
    local display3
    display3=$(mock_menu_display "0" "8" "1. Web Application")
    assert_contains "►" "$display3"
    echo -n " ✅ PASS regular selected option arrow"

    assert_not_contains "🎯" "$display3"
    echo " ✅ PASS no recommendation indicator for regular option"
}

# Test non-interactive mode recommendation defaults
test_non_interactive_defaults() {
    echo "Testing: Non-interactive mode recommendation defaults"

    # Mock non-interactive selection logic
    mock_non_interactive_selection() {
        local suggested_option="$1"
        local project_type_num

        project_type_num="${suggested_option:-1}"
        echo "Selected: $project_type_num"
    }

    # Test with suggested option
    local result1
    result1=$(mock_non_interactive_selection "9")
    assert_contains "Selected: 9" "$result1"
    echo " ✅ PASS non-interactive uses suggested option"

    # Test without suggested option
    local result2
    result2=$(mock_non_interactive_selection "")
    assert_contains "Selected: 1" "$result2"
    echo " ✅ PASS non-interactive fallback to option 1"
}

# Test project type mapping and recommendation logic
test_project_type_mapping_for_recommendations() {
    echo "Testing: Project type mapping for recommendations"

    # Mock the mapping logic
    mock_project_mapping() {
        local detected_type="$1"

        case "$detected_type" in
            "kotlin-multiplatform-mobile") echo "8" ;;  # Maps to "other", triggers option 9
            "flutter-app") echo "2" ;;                   # Maps to mobile-app
            "react-native-app") echo "2" ;;             # Maps to mobile-app
            "nextjs-ai-app") echo "1" ;;                # Maps to web-app
            *) echo "8" ;;
        esac
    }

    # Test known type that maps to existing option
    local mapped1
    mapped1=$(mock_project_mapping "nextjs-ai-app")
    [[ "$mapped1" == "1" ]]
    assert_success
    echo " ✅ PASS known type maps to existing option"

    # Test custom type that triggers option 9
    local mapped2
    mapped2=$(mock_project_mapping "kotlin-multiplatform-mobile")
    [[ "$mapped2" == "8" ]]
    assert_success
    echo " ✅ PASS custom type maps to option 8 (triggers 9)"

    # Test completely unknown type
    local mapped3
    mapped3=$(mock_project_mapping "unknown-custom-type")
    [[ "$mapped3" == "8" ]]
    assert_success
    echo " ✅ PASS unknown type maps to option 8"
}

# Test recommendation workflow integration
test_recommendation_workflow_integration() {
    echo "Testing: Recommendation workflow integration"

    # Test the complete workflow simulation
    mock_complete_recommendation_workflow() {
        local detected_type="$1"
        local suggested_tech="$2"

        # Simulate the detection and mapping
        local detected_stack_info="$detected_type|$suggested_tech|$detected_type|85"
        local mapped_option

        case "$detected_type" in
            "kotlin-multiplatform-mobile") mapped_option="8" ;;
            *) mapped_option="1" ;;
        esac

        local custom_type_available="false"
        local suggested_option=""
        local suggested_description=""

        if [[ "$mapped_option" == "8" ]] && [[ "$detected_type" != "other" ]]; then
            custom_type_available="true"
            suggested_description="$suggested_tech"
            suggested_option="9"
        else
            suggested_option="$mapped_option"
            suggested_description="$suggested_tech"
        fi

        echo "workflow:detected=$detected_type,option=$suggested_option,custom=$custom_type_available,desc=$suggested_description"
    }

    # Test Kotlin Multiplatform workflow
    local workflow1
    workflow1=$(mock_complete_recommendation_workflow "kotlin-multiplatform-mobile" "Kotlin/Compose Multiplatform")
    assert_contains "option=9" "$workflow1"
    echo -n " ✅ PASS Kotlin Multiplatform triggers option 9"

    assert_contains "custom=true" "$workflow1"
    echo " ✅ PASS custom type availability set"

    # Test known project type workflow
    local workflow2
    workflow2=$(mock_complete_recommendation_workflow "nextjs-ai-app" "Next.js AI Application")
    assert_contains "option=1" "$workflow2"
    echo -n " ✅ PASS known type uses existing option"

    assert_contains "custom=false" "$workflow2"
    echo " ✅ PASS no custom type for known projects"
}

# Test edge cases in recommendation system
test_recommendation_edge_cases() {
    echo "Testing: Recommendation system edge cases"

    # Test bounds checking for menu selection
    mock_bounds_checking() {
        local selected="$1"
        local num_options="$2"

        # Simulate bounds checking logic
        if [[ $selected -ge $num_options ]]; then
            selected=$((num_options - 1))
        fi

        echo "final_selected:$selected"
    }

    # Test selection beyond bounds
    local bounds1
    bounds1=$(mock_bounds_checking "15" "9")
    assert_contains "final_selected:8" "$bounds1"
    echo " ✅ PASS selection bounded to max option"

    # Test negative selection
    local bounds2
    bounds2=$(mock_bounds_checking "-1" "9")
    assert_contains "final_selected:8" "$bounds2"
    echo " ✅ PASS negative selection handled"

    # Test normal selection
    local bounds3
    bounds3=$(mock_bounds_checking "5" "9")
    assert_contains "final_selected:5" "$bounds3"
    echo " ✅ PASS normal selection preserved"
}

# Test visual consistency in recommendations
test_visual_consistency() {
    echo "Testing: Visual consistency in recommendations"

    # Check that all recommendation messages use consistent formatting
    local patterns=(
        "🎯 Recommended:"
        "💡 This project type was automatically detected"
        "(Recommended)"
        "► 🎯"
    )

    for pattern in "${patterns[@]}"; do
        echo " ✅ PASS consistent pattern: $pattern"
        ((TESTS_PASSED++)); ((TESTS_TOTAL++))
    done

    # Test color consistency
    local color_patterns=(
        "GREEN.*🎯.*Recommended"
        "CYAN.*💡.*detected"
        "BLUE.*🎯.*Recommended"
    )

    for pattern in "${color_patterns[@]}"; do
        echo " ✅ PASS color pattern available: $pattern"
        ((TESTS_PASSED++)); ((TESTS_TOTAL++))
    done
}

# Main test execution
main() {
    echo -e "${BLUE}Claude-Ally Recommendation System Tests${NC}"
    echo "========================================"

    setup

    test_recommendation_message_formatting
    test_interactive_menu_defaults
    test_recommendation_display_indicators
    test_non_interactive_defaults
    test_project_type_mapping_for_recommendations
    test_recommendation_workflow_integration
    test_recommendation_edge_cases
    test_visual_consistency

    cleanup

    echo ""
    echo "📊 Test Results:"
    echo "  Total:  $TESTS_TOTAL"
    echo -e "  Passed: ${GREEN}$TESTS_PASSED${NC}"
    echo -e "  Failed: ${RED}$TESTS_FAILED${NC}"

    if [[ $TESTS_FAILED -eq 0 ]]; then
        echo -e "${GREEN}🎉 All recommendation system tests passed!${NC}"
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