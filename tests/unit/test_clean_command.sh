#!/bin/bash
# Unit Tests for Clean Command
# Tests project-specific cache cleaning functionality

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
    TEST_TEMP_DIR=$(mktemp -d -t claude-ally-clean-test-XXXXXX)
    echo -e "${BLUE}🧪 Running Clean Command Unit Tests${NC}"
    echo "=========================================="
    echo ""
}

cleanup() {
    rm -rf "$TEST_TEMP_DIR" 2>/dev/null || true
    # Clean up any test cache files
    rm -f /tmp/claude_analysis_cache_test*.md 2>/dev/null || true
    rm -f /tmp/claude_stack_analysis_test*.md 2>/dev/null || true
    rm -f /tmp/claude_suggestions_test*.txt 2>/dev/null || true
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

assert_contains() {
    local expected="$1"
    local actual="$2"
    local test_name="$3"

    TESTS_TOTAL=$((TESTS_TOTAL + 1))
    if [[ "$actual" == *"$expected"* ]]; then
        echo -e "${GREEN}✅ PASS${NC} $test_name"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        echo -e "${RED}❌ FAIL${NC} $test_name"
        echo -e "   Expected to contain: ${YELLOW}$expected${NC}"
        echo -e "   Actual output: ${YELLOW}${actual:0:200}...${NC}"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
}

# Create test project with specific structure
create_test_project() {
    local project_name="$1"
    local project_dir="$TEST_TEMP_DIR/$project_name"
    mkdir -p "$project_dir"
    echo "# Test Project $project_name" > "$project_dir/README.md"
    echo "$project_dir"
}

# Create mock cache files for a project
create_mock_cache_files() {
    local project_dir="$1"
    local project_name="$2"

    # Generate the same cache key that the system would generate
    local cache_key
    cache_key=$(echo "${project_dir}_${project_name}" | md5sum 2>/dev/null | cut -d' ' -f1)

    # Create actual claude_analysis_cache file with real cache key
    echo "Project analysis for $project_name at $project_dir" > "/tmp/claude_analysis_cache_${cache_key}.md"

    # Create analysis file that contains project information
    echo "Project analysis for $project_name at $project_dir" > "/tmp/claude_stack_analysis_test_${project_name}.md"

    # Create suggestion file that contains project information
    echo "Suggestions for project $project_name located at $project_dir" > "/tmp/claude_suggestions_test_${project_name}.txt"

    # Create a generic cache file that shouldn't be cleaned
    echo "Generic cache not related to any project" > "/tmp/claude_stack_analysis_generic.md"
    echo "Generic suggestions not related to any project" > "/tmp/claude_suggestions_generic.txt"

    # Return the cache key for verification
    echo "$cache_key"
}

# Test: Clean command shows project information
test_clean_command_shows_project_info() {
    echo "Testing: Clean command shows project information"

    local project_dir
    project_dir=$(create_test_project "test-project-info")

    local result
    result=$(cd "$project_dir" && "$ROOT_DIR/claude-ally.sh" clean 2>&1)

    assert_contains "test-project-info" "$result" "Shows project name"
    assert_contains "Project directory: $project_dir" "$result" "Shows project directory"
    assert_contains "Project cache key:" "$result" "Shows cache key"
}

# Test: Clean command only removes project-specific files
test_clean_command_project_specific() {
    echo "Testing: Clean command only removes project-specific files"

    local project_dir
    project_dir=$(create_test_project "test-project-specific")
    local project_name="test-project-specific"

    # Create mock cache files and capture cache key
    local cache_key
    cache_key=$(create_mock_cache_files "$project_dir" "$project_name")

    # Verify files exist before cleaning
    if [[ ! -f "/tmp/claude_analysis_cache_${cache_key}.md" ]]; then
        assert_failure "Mock files created" "Real analysis cache file not created"
        return
    fi

    if [[ ! -f "/tmp/claude_stack_analysis_test_${project_name}.md" ]]; then
        assert_failure "Mock files created" "Project-specific analysis file not created"
        return
    fi

    if [[ ! -f "/tmp/claude_suggestions_test_${project_name}.txt" ]]; then
        assert_failure "Mock files created" "Project-specific suggestion file not created"
        return
    fi

    if [[ ! -f "/tmp/claude_stack_analysis_generic.md" ]]; then
        assert_failure "Mock files created" "Generic analysis file not created"
        return
    fi

    # Run clean command
    local result
    result=$(cd "$project_dir" && "$ROOT_DIR/claude-ally.sh" clean 2>&1)

    # Check that project-specific files were removed
    if [[ -f "/tmp/claude_analysis_cache_${cache_key}.md" ]]; then
        assert_failure "Real analysis cache file removed" "File still exists"
    else
        assert_success "Real analysis cache file removed"
    fi

    if [[ -f "/tmp/claude_stack_analysis_test_${project_name}.md" ]]; then
        assert_failure "Project-specific analysis file removed" "File still exists"
    else
        assert_success "Project-specific analysis file removed"
    fi

    if [[ -f "/tmp/claude_suggestions_test_${project_name}.txt" ]]; then
        assert_failure "Project-specific suggestion file removed" "File still exists"
    else
        assert_success "Project-specific suggestion file removed"
    fi

    # Check that generic files were NOT removed
    if [[ -f "/tmp/claude_stack_analysis_generic.md" ]]; then
        assert_success "Generic analysis file preserved"
    else
        assert_failure "Generic analysis file preserved" "File was incorrectly removed"
    fi

    if [[ -f "/tmp/claude_suggestions_generic.txt" ]]; then
        assert_success "Generic suggestion file preserved"
    else
        assert_failure "Generic suggestion file preserved" "File was incorrectly removed"
    fi

    # Check output indicates files were found and removed
    assert_contains "Project-related" "$result" "Output indicates project-specific cleaning"
}

# Test: Real claude_analysis_cache file removal (exact reproduce of www-sender issue)
test_real_claude_analysis_cache_removal() {
    echo "Testing: Real claude_analysis_cache file removal"

    local project_dir
    project_dir=$(create_test_project "real-cache-test")
    local project_name="real-cache-test"

    # Generate the exact cache key that would be used
    local cache_key
    cache_key=$(echo "${project_dir}_${project_name}" | md5sum 2>/dev/null | cut -d' ' -f1)

    # Create the exact file that contribute system creates
    echo "**STACK_ID**: test-stack
**TECH_STACK**: Test Stack
**PROJECT_TYPE**: test-app
**WORTH_ADDING**: NO - Test stack" > "/tmp/claude_analysis_cache_${cache_key}.md"

    # Verify file exists before cleaning
    if [[ ! -f "/tmp/claude_analysis_cache_${cache_key}.md" ]]; then
        assert_failure "Real cache file created" "Cache file not created"
        return
    fi

    # Run clean command
    local result
    result=$(cd "$project_dir" && "$ROOT_DIR/claude-ally.sh" clean 2>&1)

    # Verify the real cache file was removed
    if [[ -f "/tmp/claude_analysis_cache_${cache_key}.md" ]]; then
        assert_failure "Real cache file removed" "Cache file still exists after clean"
        echo "   Debug: Cache key was $cache_key"
        echo "   Debug: File path was /tmp/claude_analysis_cache_${cache_key}.md"
        echo "   Debug: Clean output was: $result"
    else
        assert_success "Real cache file removed"
    fi

    # Verify clean command reported finding and removing the file
    assert_contains "Project-specific Claude analysis cache" "$result" "Clean output mentions analysis cache"
}

# Test: Clean command with custom directory parameter
test_clean_command_custom_directory() {
    echo "Testing: Clean command with custom directory parameter"

    local project_dir
    project_dir=$(create_test_project "test-custom-dir")

    # Run clean from different directory but specify target directory
    local result
    result=$("$ROOT_DIR/claude-ally.sh" clean "$project_dir" 2>&1)

    assert_contains "test-custom-dir" "$result" "Uses specified directory name"
    assert_contains "$project_dir" "$result" "Uses specified directory path"
}

# Test: Clean command handles non-existent project gracefully
test_clean_command_nonexistent_project() {
    echo "Testing: Clean command handles non-existent project gracefully"

    local fake_dir="/tmp/nonexistent-project-12345"

    local result
    result=$("$ROOT_DIR/claude-ally.sh" clean "$fake_dir" 2>&1)

    # Should still run without errors
    assert_contains "nonexistent-project-12345" "$result" "Handles non-existent project name"
    assert_contains "No files found" "$result" "Reports no files found correctly"
}

# Test: Cache key generation consistency
test_cache_key_generation() {
    echo "Testing: Cache key generation consistency"

    local project_dir
    project_dir=$(create_test_project "test-cache-key")

    # Run clean twice and verify same cache key
    local result1
    result1=$(cd "$project_dir" && "$ROOT_DIR/claude-ally.sh" clean 2>&1 | grep "Project cache key:")

    local result2
    result2=$(cd "$project_dir" && "$ROOT_DIR/claude-ally.sh" clean 2>&1 | grep "Project cache key:")

    if [[ "$result1" == "$result2" ]] && [[ -n "$result1" ]]; then
        assert_success "Cache key generation is consistent"
    else
        assert_failure "Cache key generation is consistent" "Keys differ: $result1 vs $result2"
    fi
}

# Test: Clean command summary reporting
test_clean_command_summary() {
    echo "Testing: Clean command summary reporting"

    local project_dir
    project_dir=$(create_test_project "test-summary")

    local result
    result=$(cd "$project_dir" && "$ROOT_DIR/claude-ally.sh" clean 2>&1)

    assert_contains "Cleanup Summary:" "$result" "Shows cleanup summary"
    assert_contains "Files removed:" "$result" "Shows files removed count"
    assert_contains "Space freed:" "$result" "Shows space freed"
}

# Main test execution
main() {
    setup
    trap cleanup EXIT

    echo "🔧 Testing project-specific cache cleaning functionality..."
    echo ""

    test_clean_command_shows_project_info
    echo ""

    test_clean_command_project_specific
    echo ""

    test_real_claude_analysis_cache_removal
    echo ""

    test_clean_command_custom_directory
    echo ""

    test_clean_command_nonexistent_project
    echo ""

    test_cache_key_generation
    echo ""

    test_clean_command_summary
    echo ""

    # Test summary
    echo -e "${CYAN}📊 Clean Command Test Results:${NC}"
    echo "  Total:  $TESTS_TOTAL"
    echo -e "  Passed: ${GREEN}$TESTS_PASSED${NC}"
    echo -e "  Failed: ${RED}$TESTS_FAILED${NC}"

    if [[ $TESTS_FAILED -eq 0 ]]; then
        echo -e "${GREEN}🎉 All clean command tests passed!${NC}"
        return 0
    else
        echo -e "${RED}❌ Some clean command tests failed${NC}"
        return 1
    fi
}

# Run tests if called directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi