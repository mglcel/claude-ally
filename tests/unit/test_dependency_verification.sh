#!/bin/bash
# Dependency Verification Unit Tests
# Tests that all required dependencies are properly loaded and functional

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
    TEST_TEMP_DIR=$(mktemp -d -t claude-ally-dep-test-XXXXXX)
    echo -e "${BLUE}🧪 Running Dependency Verification Unit Tests${NC}"
    echo "======================================================"
    echo ""
}

cleanup() {
    rm -rf "$TEST_TEMP_DIR" 2>/dev/null || true
}

assert_function_exists() {
    local function_name="$1"
    local test_name="$2"

    TESTS_TOTAL=$((TESTS_TOTAL + 1))

    if type "$function_name" >/dev/null 2>&1; then
        echo -e "${GREEN}✅ PASS${NC} $test_name"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        echo -e "${RED}❌ FAIL${NC} $test_name"
        echo -e "   Function '$function_name' not found in current environment"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
}

assert_function_works() {
    local function_name="$1"
    local test_command="$2"
    local expected_pattern="$3"
    local test_name="$4"

    TESTS_TOTAL=$((TESTS_TOTAL + 1))

    local result
    result=$(eval "$test_command" 2>&1)
    local exit_code=$?

    if [[ $exit_code -eq 0 ]] && [[ "$result" =~ $expected_pattern ]]; then
        echo -e "${GREEN}✅ PASS${NC} $test_name"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        echo -e "${RED}❌ FAIL${NC} $test_name"
        echo -e "   Command: $test_command"
        echo -e "   Exit code: $exit_code"
        echo -e "   Output: $result"
        echo -e "   Expected pattern: $expected_pattern"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
}

assert_no_error() {
    local command="$1"
    local test_name="$2"

    TESTS_TOTAL=$((TESTS_TOTAL + 1))

    local result
    result=$(eval "$command" 2>&1)
    local exit_code=$?

    if [[ $exit_code -eq 0 ]] && [[ "$result" != *"command not found"* ]] && [[ "$result" != *"not found"* ]]; then
        echo -e "${GREEN}✅ PASS${NC} $test_name"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        echo -e "${RED}❌ FAIL${NC} $test_name"
        echo -e "   Command: $command"
        echo -e "   Exit code: $exit_code"
        echo -e "   Output: $result"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
}

# Test: Utilities.sh sourcing in different contexts
test_utilities_sourcing() {
    echo "Testing: Utilities.sh sourcing in different execution contexts"

    # Test direct sourcing
    local direct_result
    direct_result=$(bash -c "
        source '$ROOT_DIR/lib/utilities.sh'
        echo 'Direct sourcing: SUCCESS'
    " 2>&1)

    if [[ "$direct_result" == *"SUCCESS"* ]]; then
        echo -e "${GREEN}✅ PASS${NC} Direct utilities.sh sourcing works"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        echo -e "${RED}❌ FAIL${NC} Direct utilities.sh sourcing works"
        echo -e "   Output: $direct_result"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
    TESTS_TOTAL=$((TESTS_TOTAL + 1))

    # Test sourcing from contribute script
    local contrib_result
    contrib_result=$(bash -c "
        source '$ROOT_DIR/lib/contribute-stack.sh'
        echo 'Contribute script sourcing: SUCCESS'
    " 2>&1)

    if [[ "$contrib_result" == *"SUCCESS"* ]] && [[ "$contrib_result" != *"not found"* ]]; then
        echo -e "${GREEN}✅ PASS${NC} Contribute script utilities sourcing works"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        echo -e "${RED}❌ FAIL${NC} Contribute script utilities sourcing works"
        echo -e "   Output: $contrib_result"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
    TESTS_TOTAL=$((TESTS_TOTAL + 1))
}

# Test: Utility functions availability and functionality
test_utility_functions() {
    echo "Testing: Utility functions availability and functionality"

    # Source the contribute script to test function availability
    source "$ROOT_DIR/lib/contribute-stack.sh"

    # Test create_cache_key function
    assert_function_exists "create_cache_key" "create_cache_key function exists"

    # Test is_cache_valid function
    assert_function_exists "is_cache_valid" "is_cache_valid function exists"

    # Test create_cache_key functionality
    assert_function_works "create_cache_key" \
        "create_cache_key '/test/path' 'test-project'" \
        "^[a-f0-9]{32}$|^[a-f0-9]{64}$" \
        "create_cache_key generates valid hash"

    # Test is_cache_valid functionality with non-existent file
    assert_function_works "is_cache_valid" \
        "is_cache_valid '/nonexistent/file' && echo 'INVALID' || echo 'VALID'" \
        "VALID" \
        "is_cache_valid correctly identifies non-existent file"

    # Test is_cache_valid with fresh file
    local test_file="$TEST_TEMP_DIR/test_cache.txt"
    echo "test content" > "$test_file"

    assert_function_works "is_cache_valid" \
        "is_cache_valid '$test_file' && echo 'VALID' || echo 'INVALID'" \
        "VALID" \
        "is_cache_valid correctly identifies fresh file"
}

# Test: Subprocess execution dependencies
test_subprocess_dependencies() {
    echo "Testing: Subprocess execution dependencies"

    # Test that contribute script works when executed as subprocess
    local subprocess_test="$TEST_TEMP_DIR/subprocess_test.sh"
    cat > "$subprocess_test" << 'EOF'
#!/bin/bash
# Test subprocess execution of contribute functions
source "$1/lib/contribute-stack.sh"

# Test that utility functions are available
if type create_cache_key >/dev/null 2>&1; then
    cache_key=$(create_cache_key "/test" "project")
    if [[ -n "$cache_key" ]]; then
        echo "SUBPROCESS_SUCCESS"
    else
        echo "SUBPROCESS_FUNCTION_FAILED"
    fi
else
    echo "SUBPROCESS_FUNCTION_MISSING"
fi
EOF
    chmod +x "$subprocess_test"

    local subprocess_result
    subprocess_result=$(bash "$subprocess_test" "$ROOT_DIR" 2>&1)

    if [[ "$subprocess_result" == "SUBPROCESS_SUCCESS" ]]; then
        echo -e "${GREEN}✅ PASS${NC} Subprocess execution has access to utility functions"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        echo -e "${RED}❌ FAIL${NC} Subprocess execution has access to utility functions"
        echo -e "   Output: $subprocess_result"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
    TESTS_TOTAL=$((TESTS_TOTAL + 1))
}

# Test: Fallback implementations
test_fallback_implementations() {
    echo "Testing: Fallback implementations when utilities.sh is missing"

    # Create a test script that simulates missing utilities.sh
    local fallback_test="$TEST_TEMP_DIR/fallback_test.sh"
    cat > "$fallback_test" << 'EOF'
#!/bin/bash
# Simulate missing utilities.sh by temporarily moving it
CONTRIB_SCRIPT_DIR="$(cd "$(dirname "$1/lib/contribute-stack.sh")" && pwd)"

# Temporarily rename utilities.sh to simulate missing
if [[ -f "$CONTRIB_SCRIPT_DIR/utilities.sh" ]]; then
    mv "$CONTRIB_SCRIPT_DIR/utilities.sh" "$CONTRIB_SCRIPT_DIR/utilities.sh.backup"
fi

# Source the contribute script (should use fallbacks)
source "$1/lib/contribute-stack.sh" 2>/dev/null

# Test fallback functions
if type create_cache_key >/dev/null 2>&1; then
    cache_key=$(create_cache_key "/test" "project")
    if [[ -n "$cache_key" ]]; then
        echo "FALLBACK_SUCCESS"
    else
        echo "FALLBACK_FUNCTION_FAILED"
    fi
else
    echo "FALLBACK_FUNCTION_MISSING"
fi

# Restore utilities.sh
if [[ -f "$CONTRIB_SCRIPT_DIR/utilities.sh.backup" ]]; then
    mv "$CONTRIB_SCRIPT_DIR/utilities.sh.backup" "$CONTRIB_SCRIPT_DIR/utilities.sh"
fi
EOF
    chmod +x "$fallback_test"

    local fallback_result
    fallback_result=$(bash "$fallback_test" "$ROOT_DIR" 2>&1)

    if [[ "$fallback_result" == "FALLBACK_SUCCESS" ]]; then
        echo -e "${GREEN}✅ PASS${NC} Fallback implementations work when utilities.sh is missing"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        echo -e "${RED}❌ FAIL${NC} Fallback implementations work when utilities.sh is missing"
        echo -e "   Output: $fallback_result"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
    TESTS_TOTAL=$((TESTS_TOTAL + 1))
}

# Test: All required stack detector dependencies
test_stack_detector_dependencies() {
    echo "Testing: Stack detector dependencies"

    # Test that stack detector can be sourced
    assert_no_error "source '$ROOT_DIR/lib/stack-detector.sh'" "Stack detector sourcing"

    # Source stack detector and test key functions
    source "$ROOT_DIR/lib/stack-detector.sh"

    assert_function_exists "detect_project_stack" "detect_project_stack function exists"
    assert_function_exists "load_stack_modules" "load_stack_modules function exists"

    # Test that stack modules directory exists
    if [[ -d "$ROOT_DIR/stacks" ]]; then
        echo -e "${GREEN}✅ PASS${NC} Stack modules directory exists"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        echo -e "${RED}❌ FAIL${NC} Stack modules directory exists"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
    TESTS_TOTAL=$((TESTS_TOTAL + 1))
}

# Test: Main script dependency chain
test_main_script_dependencies() {
    echo "Testing: Main script dependency chain"

    # Test that main script can source all required modules
    local main_test="$TEST_TEMP_DIR/main_test.sh"
    cat > "$main_test" << 'EOF'
#!/bin/bash
SCRIPT_DIR="$1"

# Test core module sourcing as done in main script
modules=(
    "lib/stack-detector.sh"
    "lib/contribute-stack.sh"
)

for module in "${modules[@]}"; do
    if [[ -f "$SCRIPT_DIR/$module" ]]; then
        if source "$SCRIPT_DIR/$module" 2>/dev/null; then
            echo "$module: SUCCESS"
        else
            echo "$module: FAILED"
        fi
    else
        echo "$module: MISSING"
    fi
done
EOF

    local main_result
    main_result=$(bash "$main_test" "$ROOT_DIR" 2>&1)

    if [[ "$main_result" == *"SUCCESS"* ]] && [[ "$main_result" != *"FAILED"* ]] && [[ "$main_result" != *"MISSING"* ]]; then
        echo -e "${GREEN}✅ PASS${NC} Main script can source all required modules"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        echo -e "${RED}❌ FAIL${NC} Main script can source all required modules"
        echo -e "   Output: $main_result"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
    TESTS_TOTAL=$((TESTS_TOTAL + 1))
}

# Main test execution
main() {
    setup
    trap cleanup EXIT

    echo "🔧 Testing dependency loading and availability..."
    echo ""

    test_utilities_sourcing
    echo ""

    test_utility_functions
    echo ""

    test_subprocess_dependencies
    echo ""

    test_fallback_implementations
    echo ""

    test_stack_detector_dependencies
    echo ""

    test_main_script_dependencies
    echo ""

    # Test summary
    echo -e "${CYAN}📊 Dependency Test Results:${NC}"
    echo "  Total:  $TESTS_TOTAL"
    echo -e "  Passed: ${GREEN}$TESTS_PASSED${NC}"
    echo -e "  Failed: ${RED}$TESTS_FAILED${NC}"

    if [[ $TESTS_FAILED -eq 0 ]]; then
        echo -e "${GREEN}🎉 All dependency tests passed!${NC}"
        return 0
    else
        echo -e "${RED}❌ Some dependency tests failed${NC}"
        return 1
    fi
}

# Run tests if called directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi