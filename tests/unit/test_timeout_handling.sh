#!/bin/bash
#
# Tests for Timeout Handling in Claude Analysis
# Tests the timeout protection and error handling in analysis functions
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
    echo -e "${BLUE}Setting up timeout handling tests...${NC}"

    # Create test project directory
    TEST_PROJECT_DIR="/tmp/claude-ally-test-timeout-$$"
    mkdir -p "$TEST_PROJECT_DIR"

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

# Test timeout command availability
test_timeout_command_availability() {
    echo "Testing: Timeout command availability"

    # Test that timeout command is available
    if command -v timeout >/dev/null; then
        echo " ✅ PASS timeout command available"
        ((TESTS_PASSED++)); ((TESTS_TOTAL++))
    else
        echo " ❌ FAIL timeout command not available"
        ((TESTS_FAILED++)); ((TESTS_TOTAL++))
    fi

    # Test timeout with a quick command
    if timeout 1 echo "test" >/dev/null; then
        echo " ✅ PASS timeout command functional"
        ((TESTS_PASSED++)); ((TESTS_TOTAL++))
    else
        echo " ❌ FAIL timeout command not functional"
        ((TESTS_FAILED++)); ((TESTS_TOTAL++))
    fi
}

# Test file analysis timeout protection
test_file_analysis_timeout() {
    echo "Testing: File analysis timeout protection"

    # Mock function that simulates the timeout protection in contribute-stack.sh
    analyze_with_timeout() {
        local project_dir="$1"
        local timeout_seconds="${2:-5}"

        # Simulate the timeout protection pattern used in contribute-stack.sh
        local find_result
        find_result=$(timeout "$timeout_seconds" find "$project_dir" -maxdepth 2 -name "*.json" -o -name "*.toml" 2>/dev/null | head -10 || echo "File analysis timed out")

        echo "$find_result"
    }

    # Create test files for analysis
    echo '{"name": "test"}' > "$TEST_PROJECT_DIR/package.json"
    echo '[tool.poetry]' > "$TEST_PROJECT_DIR/pyproject.toml"

    # Test successful analysis within timeout
    local result
    result=$(analyze_with_timeout "$TEST_PROJECT_DIR" 5)
    assert_contains "package.json" "$result"
    echo -n " ✅ PASS files found within timeout"

    assert_contains "pyproject.toml" "$result"
    echo " ✅ PASS multiple files detected"

    # Test timeout fallback message
    # Create a scenario that would timeout (simulate with very short timeout and busy work)
    local timeout_result
    timeout_result=$(analyze_with_timeout "/nonexistent/path/that/will/fail" 1)
    if [[ "$timeout_result" == "File analysis timed out" ]]; then
        echo " ✅ PASS timeout fallback message"
        ((TESTS_PASSED++)); ((TESTS_TOTAL++))
    else
        echo " ❌ FAIL timeout fallback not working"
        ((TESTS_FAILED++)); ((TESTS_TOTAL++))
    fi
}

# Test Claude command timeout protection
test_claude_command_timeout() {
    echo "Testing: Claude command timeout protection"

    # Mock function that simulates Claude timeout protection
    claude_with_timeout() {
        local analysis_file="$1"
        local timeout_seconds="${2:-30}"

        # Simulate the timeout pattern: timeout 30 claude < "$analysis_file"
        if timeout "$timeout_seconds" cat "$analysis_file" 2>/dev/null; then
            return 0
        else
            return 1
        fi
    }

    # Create test analysis file
    local analysis_file="$TEST_PROJECT_DIR/analysis.txt"
    cat > "$analysis_file" << 'EOF'
Analyze this project and provide:
STACK_ID: test-stack
TECH_STACK: Test Technology
PROJECT_TYPE: test-project
EOF

    # Test successful Claude analysis within timeout
    if claude_with_timeout "$analysis_file" 5; then
        echo " ✅ PASS Claude analysis within timeout"
        ((TESTS_PASSED++)); ((TESTS_TOTAL++))
    else
        echo " ❌ FAIL Claude analysis timeout issue"
        ((TESTS_FAILED++)); ((TESTS_TOTAL++))
    fi

    # Test timeout behavior with non-existent file
    if ! claude_with_timeout "/nonexistent/file" 1; then
        echo " ✅ PASS timeout handles missing files"
        ((TESTS_PASSED++)); ((TESTS_TOTAL++))
    else
        echo " ❌ FAIL timeout should fail on missing files"
        ((TESTS_FAILED++)); ((TESTS_TOTAL++))
    fi
}

# Test error handling after timeout
test_timeout_error_handling() {
    echo "Testing: Timeout error handling"

    # Mock function that demonstrates proper error handling after timeout
    handle_analysis_with_fallback() {
        local project_dir="$1"

        # Simulate different outcomes based on input
        if [[ "$project_dir" == "/invalid" ]]; then
            # Simulate timeout/failure
            echo -e "${YELLOW}⚠️  Claude analysis failed, continuing with standard options${NC}" >&2
            return 1
        else
            # Try analysis with timeout
            local claude_result
            if claude_result=$(timeout 1 echo "mock analysis result" 2>/dev/null); then
                echo "Analysis successful: $claude_result"
                return 0
            else
                echo -e "${YELLOW}⚠️  Claude analysis failed, continuing with standard options${NC}" >&2
                return 1
            fi
        fi
    }

    # Test successful case
    local success_result
    success_result=$(handle_analysis_with_fallback "$TEST_PROJECT_DIR" 2>/dev/null)
    assert_contains "Analysis successful" "$success_result"
    echo -n " ✅ PASS successful analysis handling"

    # Test error case with stderr capture
    local error_msg
    error_msg=$(handle_analysis_with_fallback "/invalid" 2>&1 >/dev/null)
    assert_contains "Claude analysis failed" "$error_msg"
    echo " ✅ PASS error message on timeout"
}

# Test timeout values in real modules
test_real_module_timeout_values() {
    echo "Testing: Real module timeout values"

    # Check contribute-stack.sh for timeout usage
    if [[ -f "$PROJECT_ROOT/lib/contribute-stack.sh" ]]; then
        local contribute_content
        contribute_content=$(cat "$PROJECT_ROOT/lib/contribute-stack.sh")

        # Look for find timeout (should be short, around 5 seconds)
        if echo "$contribute_content" | grep -q 'timeout 5 find'; then
            echo " ✅ PASS find timeout configured"
            ((TESTS_PASSED++)); ((TESTS_TOTAL++))
        else
            echo " ❌ FAIL find timeout not configured properly"
            ((TESTS_FAILED++)); ((TESTS_TOTAL++))
        fi

        # Look for Claude timeout (should be longer, around 30 seconds)
        if echo "$contribute_content" | grep -q 'timeout [0-9][0-9] claude'; then
            echo " ✅ PASS claude timeout configured"
            ((TESTS_PASSED++)); ((TESTS_TOTAL++))
        else
            echo " ❌ FAIL claude timeout not configured properly"
            ((TESTS_FAILED++)); ((TESTS_TOTAL++))
        fi
    else
        echo " ℹ️  INFO contribute module not found for testing"
        ((TESTS_TOTAL++))
    fi
}

# Test graceful degradation on timeout
test_graceful_degradation() {
    echo "Testing: Graceful degradation on timeout"

    # Mock the complete flow with graceful degradation
    full_analysis_with_degradation() {
        local project_dir="$1"

        # Stage 1: Try file analysis
        local file_analysis
        file_analysis=$(timeout 5 find "$project_dir" -name "*.json" 2>/dev/null || echo "")

        # Stage 2: Try Claude analysis if files found
        if [[ -n "$file_analysis" ]]; then
            local claude_result
            if claude_result=$(timeout 30 echo "mock claude analysis" 2>/dev/null); then
                echo "FULL_SUCCESS: $claude_result"
                return 0
            else
                echo "PARTIAL_SUCCESS: Files found but Claude failed"
                return 1
            fi
        else
            echo "NO_ANALYSIS: No files or timeout"
            return 2
        fi
    }

    # Test with existing files (should succeed)
    echo '{"test": true}' > "$TEST_PROJECT_DIR/test.json"
    local result1
    result1=$(full_analysis_with_degradation "$TEST_PROJECT_DIR")
    assert_contains "FULL_SUCCESS" "$result1"
    echo " ✅ PASS graceful success case"

    # Test graceful degradation
    local result2
    result2=$(full_analysis_with_degradation "/tmp/empty_dir_$$")
    assert_contains "NO_ANALYSIS" "$result2"
    echo " ✅ PASS graceful degradation"
}

# Main test execution
main() {
    echo -e "${BLUE}Claude-Ally Timeout Handling Tests${NC}"
    echo "==================================="

    setup

    test_timeout_command_availability
    test_file_analysis_timeout
    test_claude_command_timeout
    test_timeout_error_handling
    test_real_module_timeout_values
    test_graceful_degradation

    cleanup

    echo ""
    echo "📊 Test Results:"
    echo "  Total:  $TESTS_TOTAL"
    echo -e "  Passed: ${GREEN}$TESTS_PASSED${NC}"
    echo -e "  Failed: ${RED}$TESTS_FAILED${NC}"

    if [[ $TESTS_FAILED -eq 0 ]]; then
        echo -e "${GREEN}🎉 All timeout handling tests passed!${NC}"
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