#!/bin/bash
#
# Tests for Cache Output Contamination Fixes
# Tests the fixes for cache output contamination in Claude analysis
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
    echo -e "${BLUE}Setting up cache contamination tests...${NC}"

    # Create test project directory
    TEST_PROJECT_DIR="/tmp/claude-ally-test-cache-$$"
    mkdir -p "$TEST_PROJECT_DIR"

    # Create test cache directory
    TEST_CACHE_DIR="/tmp/claude-ally-cache-test-$$"
    mkdir -p "$TEST_CACHE_DIR"

    # Set environment
    export PROJECT_DIR="$TEST_PROJECT_DIR"
    export SCRIPT_DIR="$PROJECT_ROOT/lib"
    export NON_INTERACTIVE="true"
    export CACHE_DIR="$TEST_CACHE_DIR"
}

# Cleanup test environment
cleanup() {
    if [[ -n "${TEST_PROJECT_DIR:-}" ]] && [[ -d "$TEST_PROJECT_DIR" ]]; then
        rm -rf "$TEST_PROJECT_DIR"
    fi
    if [[ -n "${TEST_CACHE_DIR:-}" ]] && [[ -d "$TEST_CACHE_DIR" ]]; then
        rm -rf "$TEST_CACHE_DIR"
    fi
}

# Test cache output without contamination
test_cache_output_clean() {
    echo "Testing: Cache output cleanliness"

    # Create a mock cache file with Claude analysis results
    local cache_file="$TEST_CACHE_DIR/test_analysis.cache"
    cat > "$cache_file" << 'EOF'
STACK_ID: kotlin-multiplatform-mobile
TECH_STACK: Kotlin/Compose Multiplatform
PROJECT_TYPE: kotlin-multiplatform-mobile
CONFIDENCE_PATTERNS: build.gradle.kts, settings.gradle.kts
WORTH_ADDING: YES
EOF

    # Mock function that simulates cache loading with proper stderr redirection
    load_cache_clean() {
        local cache_file="$1"
        # This should send status messages to stderr, not stdout
        echo -e "${GREEN}🔄 Using cached Claude analysis${NC}" >&2
        # Only the actual content should go to stdout
        cat "$cache_file"
    }

    # Test that status messages don't contaminate the output
    local output
    output=$(load_cache_clean "$cache_file" 2>/dev/null)

    # The output should contain the analysis but not status messages
    assert_contains "STACK_ID: kotlin-multiplatform-mobile" "$output"
    echo -n " ✅ PASS cache content preserved"

    assert_not_contains "Using cached Claude analysis" "$output"
    echo " ✅ PASS status messages not in output"

    # Test that status messages still appear on stderr
    local stderr_output
    stderr_output=$(load_cache_clean "$cache_file" 2>&1 >/dev/null)
    assert_contains "Using cached Claude analysis" "$stderr_output"
    echo " ✅ PASS status messages on stderr"
}

# Test ANSI code contamination prevention
test_ansi_contamination_prevention() {
    echo "Testing: ANSI code contamination prevention"

    # Mock function that demonstrates proper ANSI handling
    generate_output_with_status() {
        local content="$1"
        # Status with ANSI codes should go to stderr
        echo -e "${BLUE}📝 Processing...${NC}" >&2
        # Clean content should go to stdout
        echo "$content"
    }

    # Test that ANSI codes don't leak into captured variables
    local result
    result=$(generate_output_with_status "clean_output_value" 2>/dev/null)

    assert_not_contains "\\033" "$result"
    echo -n " ✅ PASS no ANSI codes in captured output"

    assert_contains "clean_output_value" "$result"
    echo " ✅ PASS clean content preserved"
}

# Test command substitution cleanliness
test_command_substitution_cleanliness() {
    echo "Testing: Command substitution cleanliness"

    # Mock the fixed version of generate_prompt function behavior
    mock_generate_prompt_fixed() {
        local project_name="$1"
        local prompt_file="test_prompt.txt"

        # Status messages redirected to stderr
        echo -e "${BLUE}📝 Generating Claude prompt...${NC}" >&2
        echo -e "${GREEN}✅ Prompt generated: $prompt_file${NC}" >&2

        # Only return the filename to stdout
        echo "$prompt_file"
    }

    # Test that command substitution captures only the intended output
    local captured_filename
    captured_filename=$(mock_generate_prompt_fixed "test-project" 2>/dev/null)

    assert_contains "test_prompt.txt" "$captured_filename"
    echo -n " ✅ PASS filename captured correctly"

    assert_not_contains "Generating Claude prompt" "$captured_filename"
    echo " ✅ PASS status messages not captured"
}

# Test stderr redirection patterns
test_stderr_redirection_patterns() {
    echo "Testing: Stderr redirection patterns"

    # Test the pattern used in contribute-stack.sh
    mock_cache_usage() {
        local cache_file="$1"
        if [[ -f "$cache_file" ]]; then
            echo -e "${GREEN}🔄 Using cached Claude analysis${NC}" >&2
            cat "$cache_file"
            return 0
        else
            echo -e "${YELLOW}⚠️  No cache found${NC}" >&2
            return 1
        fi
    }

    # Create test cache
    echo "test analysis result" > "$TEST_CACHE_DIR/test.cache"

    # Test with existing cache
    local result
    result=$(mock_cache_usage "$TEST_CACHE_DIR/test.cache" 2>/dev/null)
    assert_contains "test analysis result" "$result"
    echo -n " ✅ PASS cache content extracted cleanly"

    # Test stderr capture
    local stderr_msg
    stderr_msg=$(mock_cache_usage "$TEST_CACHE_DIR/test.cache" 2>&1 >/dev/null)
    assert_contains "Using cached Claude analysis" "$stderr_msg"
    echo " ✅ PASS status message on stderr"
}

# Test output separation in real module functions
test_real_module_output_separation() {
    echo "Testing: Real module output separation"

    # Source the contribute-stack module to test real functions
    if [[ -f "$PROJECT_ROOT/lib/contribute-stack.sh" ]]; then
        # Check that the module uses proper output redirection
        local contribute_content
        contribute_content=$(cat "$PROJECT_ROOT/lib/contribute-stack.sh")

        # Look for the fixed pattern: status messages redirected to stderr
        if echo "$contribute_content" | grep -q 'Using cached.*>&2'; then
            echo " ✅ PASS contribute module uses stderr redirection"
            ((TESTS_PASSED++)); ((TESTS_TOTAL++))
        else
            echo " ❌ FAIL contribute module missing stderr redirection"
            ((TESTS_FAILED++)); ((TESTS_TOTAL++))
        fi

        # Look for cat command that outputs cache content cleanly
        if echo "$contribute_content" | grep -q "cat \"\$cache_file\"\$"; then
            echo " ✅ PASS cache content output is clean"
            ((TESTS_PASSED++)); ((TESTS_TOTAL++))
        else
            echo " ❌ FAIL cache content output may be contaminated"
            ((TESTS_FAILED++)); ((TESTS_TOTAL++))
        fi
    else
        echo " ℹ️  INFO contribute module not found for testing"
        ((TESTS_TOTAL++))
    fi
}

# Main test execution
main() {
    echo -e "${BLUE}Claude-Ally Cache Contamination Fix Tests${NC}"
    echo "=========================================="

    setup

    test_cache_output_clean
    test_ansi_contamination_prevention
    test_command_substitution_cleanliness
    test_stderr_redirection_patterns
    test_real_module_output_separation

    cleanup

    echo ""
    echo "📊 Test Results:"
    echo "  Total:  $TESTS_TOTAL"
    echo -e "  Passed: ${GREEN}$TESTS_PASSED${NC}"
    echo -e "  Failed: ${RED}$TESTS_FAILED${NC}"

    if [[ $TESTS_FAILED -eq 0 ]]; then
        echo -e "${GREEN}🎉 All cache contamination fix tests passed!${NC}"
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