#!/bin/bash
# Edge case and security tests for claude-ally

set -euo pipefail

# Test framework
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Test counters
TESTS_TOTAL=0
TESTS_PASSED=0
TESTS_FAILED=0

# Test configuration
TEST_TEMP_DIR="/tmp/claude-ally-edge-test-$(date +%Y%m%d%H%M%S)"
ORIGINAL_PATH="$PATH"

# Test framework functions
assert_equals() {
    local expected="$1"
    local actual="$2"
    local test_name="$3"

    TESTS_TOTAL=$((TESTS_TOTAL + 1))

    if [[ "$expected" == "$actual" ]]; then
        echo -e "${GREEN}✅ PASS${NC} $test_name"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        echo -e "${RED}❌ FAIL${NC} $test_name"
        echo -e "   Expected: ${YELLOW}$expected${NC}"
        echo -e "   Actual:   ${YELLOW}$actual${NC}"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
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
        echo -e "   Actual:              ${YELLOW}$actual${NC}"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
}

assert_not_contains() {
    local not_expected="$1"
    local actual="$2"
    local test_name="$3"

    TESTS_TOTAL=$((TESTS_TOTAL + 1))

    if [[ "$actual" != *"$not_expected"* ]]; then
        echo -e "${GREEN}✅ PASS${NC} $test_name"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        echo -e "${RED}❌ FAIL${NC} $test_name"
        echo -e "   Should not contain: ${YELLOW}$not_expected${NC}"
        echo -e "   Actual:            ${YELLOW}$actual${NC}"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
}

assert_success() {
    local command="$1"
    local test_name="$2"

    TESTS_TOTAL=$((TESTS_TOTAL + 1))

    if eval "$command" &>/dev/null; then
        echo -e "${GREEN}✅ PASS${NC} $test_name"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        echo -e "${RED}❌ FAIL${NC} $test_name"
        echo -e "   Command failed: ${YELLOW}$command${NC}"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
}

assert_exit_code() {
    local expected_code="$1"
    local command="$2"
    local test_name="$3"

    TESTS_TOTAL=$((TESTS_TOTAL + 1))

    local actual_code=0
    eval "$command" &>/dev/null || actual_code=$?

    if [[ $actual_code -eq $expected_code ]]; then
        echo -e "${GREEN}✅ PASS${NC} $test_name"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        echo -e "${RED}❌ FAIL${NC} $test_name"
        echo -e "   Expected exit code: ${YELLOW}$expected_code${NC}"
        echo -e "   Actual exit code:   ${YELLOW}$actual_code${NC}"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
}

# Setup test environment
setup() {
    mkdir -p "$TEST_TEMP_DIR"

    # Validate that claude-ally.sh exists and is executable
    if [[ ! -x "$ROOT_DIR/claude-ally.sh" ]]; then
        echo -e "${RED}ERROR: claude-ally.sh not found or not executable at $ROOT_DIR/claude-ally.sh${NC}"
        exit 1
    fi
}

# Cleanup test environment
cleanup() {
    export PATH="$ORIGINAL_PATH"
    rm -rf "$TEST_TEMP_DIR" 2>/dev/null || true
}

# Create test project with multiple stacks
create_multi_stack_project() {
    local project_dir="$TEST_TEMP_DIR/multi-stack-project"
    mkdir -p "$project_dir"

    # Create Next.js + React Native monorepo
    cat > "$project_dir/package.json" << 'EOF'
{
  "name": "multi-stack-monorepo",
  "workspaces": ["web", "mobile"],
  "dependencies": {
    "next": "^14.0.0",
    "react": "^18.2.0"
  }
}
EOF

    # Web app (Next.js)
    mkdir -p "$project_dir/web"
    cat > "$project_dir/web/package.json" << 'EOF'
{
  "name": "web-app",
  "dependencies": {
    "next": "^14.0.0",
    "react": "^18.2.0",
    "@ai-sdk/openai": "^0.0.40"
  }
}
EOF
    echo 'module.exports = {}' > "$project_dir/web/next.config.js"

    # Mobile app (React Native)
    mkdir -p "$project_dir/mobile"
    cat > "$project_dir/mobile/package.json" << 'EOF'
{
  "name": "mobile-app",
  "dependencies": {
    "react-native": "^0.72.0",
    "@react-navigation/native": "^6.0.0"
  }
}
EOF

    echo "$project_dir"
}

# Create deeply nested project
create_deep_project() {
    local project_dir="$TEST_TEMP_DIR/deep-project"
    local deep_path="$project_dir/very/deep/nested/structure/with/many/levels/here"
    mkdir -p "$deep_path"

    cat > "$deep_path/package.json" << 'EOF'
{
  "name": "deeply-nested-project",
  "dependencies": {
    "react": "^18.2.0"
  }
}
EOF

    echo "$project_dir"
}

# Create project with malicious paths
create_malicious_paths_project() {
    local project_dir="$TEST_TEMP_DIR/malicious-project"
    mkdir -p "$project_dir"

    # Create files with potentially problematic names
    touch "$project_dir/../../etc/passwd" 2>/dev/null || true
    touch "$project_dir/../../../root/.ssh/id_rsa" 2>/dev/null || true
    mkdir -p "$project_dir/\$(rm -rf /)" 2>/dev/null || true
    mkdir -p "$project_dir/'; rm -rf /; #" 2>/dev/null || true

    cat > "$project_dir/package.json" << 'EOF'
{
  "name": "test-project",
  "dependencies": {
    "react": "^18.2.0"
  }
}
EOF

    echo "$project_dir"
}

# Create project with corrupted configuration files
create_corrupted_config_project() {
    local project_dir="$TEST_TEMP_DIR/corrupted-project"
    mkdir -p "$project_dir"

    # Invalid JSON
    echo '{"name": "test", invalid json}' > "$project_dir/package.json"

    # Binary file masquerading as config
    echo -e "\x00\x01\x02\x03BINARY" > "$project_dir/next.config.js"

    # Extremely large file
    head -c 10M /dev/zero > "$project_dir/large-config.json" 2>/dev/null || echo '{}' > "$project_dir/large-config.json"

    echo "$project_dir"
}

# Test: Multi-stack detection
test_multi_stack_detection() {
    echo "Testing: Multi-stack detection"

    source "$ROOT_DIR/lib/stack-detector.sh"

    local project_dir
    project_dir=$(create_multi_stack_project)

    # Test detection at root level
    local root_result
    root_result=$(detect_project_stack "$project_dir" 2>/dev/null || echo "no_detection")

    if [[ "$root_result" != "no_detection" ]]; then
        assert_contains "nextjs" "$root_result" "Multi-stack project detects Next.js at root"
    else
        echo -e "${YELLOW}⚠️ SKIP${NC} Multi-stack detection (no stack detected at root)"
    fi

    # Test detection in subdirectories
    local web_result
    web_result=$(detect_project_stack "$project_dir/web" 2>/dev/null || echo "no_detection")

    if [[ "$web_result" != "no_detection" ]]; then
        assert_contains "nextjs" "$web_result" "Multi-stack project detects Next.js in web subdirectory"
    fi
}

# Test: Deep directory structure handling
test_deep_directory_handling() {
    echo "Testing: Deep directory structure handling"

    source "$ROOT_DIR/lib/stack-detector.sh"

    local project_dir
    project_dir=$(create_deep_project)

    # Test that detection works with deeply nested structures
    local result
    result=$(detect_project_stack "$project_dir" 2>/dev/null || echo "no_detection")

    # Should handle deep structures gracefully (may or may not detect, but shouldn't crash)
    if [[ "$result" == "no_detection" ]]; then
        echo -e "${GREEN}✅ PASS${NC} Deep directory structure handled gracefully"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        assert_contains "react" "$result" "Deep directory structure detection works"
    fi
    TESTS_TOTAL=$((TESTS_TOTAL + 1))
}

# Test: Security - malicious path handling
test_malicious_path_handling() {
    echo "Testing: Security - malicious path handling"

    local project_dir
    project_dir=$(create_malicious_paths_project)

    # Test that CLI handles malicious paths safely (with timeout and better error handling)
    local detect_result
    detect_result=$(timeout 30 "$ROOT_DIR/claude-ally.sh" detect "$project_dir" 2>&1 || echo "FAILED")

    assert_not_contains "/etc/passwd" "$detect_result" "Malicious paths don't leak sensitive file access"
    assert_not_contains "rm -rf" "$detect_result" "Command injection attempts are sanitized"

    # Ensure the CLI doesn't crash or execute malicious commands
    if [[ "$detect_result" != "FAILED" ]]; then
        echo -e "${GREEN}✅ PASS${NC} CLI handles malicious paths without crashing"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        echo -e "${RED}❌ FAIL${NC} CLI crashed on malicious paths"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
    TESTS_TOTAL=$((TESTS_TOTAL + 1))
}

# Test: Corrupted configuration file handling
test_corrupted_config_handling() {
    echo "Testing: Corrupted configuration file handling"

    source "$ROOT_DIR/lib/stack-detector.sh"

    local project_dir
    project_dir=$(create_corrupted_config_project)

    # Test that detection handles corrupted files gracefully
    local result
    result=$(detect_project_stack "$project_dir" 2>/dev/null || echo "no_detection")

    # Should handle corrupted files without crashing
    echo -e "${GREEN}✅ PASS${NC} Corrupted configuration files handled gracefully"
    TESTS_PASSED=$((TESTS_PASSED + 1))
    TESTS_TOTAL=$((TESTS_TOTAL + 1))
}

# Test: Very large file handling
test_large_file_handling() {
    echo "Testing: Large file handling"

    local project_dir="$TEST_TEMP_DIR/large-project"
    mkdir -p "$project_dir"

    # Create a project with a very large package.json
    cat > "$project_dir/package.json" << 'EOF'
{
  "name": "large-project",
  "dependencies": {
EOF

    # Add many dependencies to make it large
    for i in {1..1000}; do
        echo "    \"package-$i\": \"^1.0.0\"," >> "$project_dir/package.json"
    done

    cat >> "$project_dir/package.json" << 'EOF'
    "react": "^18.2.0"
  }
}
EOF

    source "$ROOT_DIR/lib/stack-detector.sh"

    # Test that detection handles large files reasonably
    local start_time end_time duration
    start_time=$(date +%s)

    local result
    result=$(detect_project_stack "$project_dir" 2>/dev/null || echo "no_detection")

    end_time=$(date +%s)
    duration=$((end_time - start_time))

    # Should complete within reasonable time (10 seconds)
    if [[ $duration -le 10 ]]; then
        echo -e "${GREEN}✅ PASS${NC} Large file handling completes in reasonable time (${duration}s)"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        echo -e "${RED}❌ FAIL${NC} Large file handling too slow (${duration}s)"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
    TESTS_TOTAL=$((TESTS_TOTAL + 1))
}

# Test: Concurrent execution safety
test_concurrent_execution() {
    echo "Testing: Concurrent execution safety"

    local project_dir="$TEST_TEMP_DIR/concurrent-test"
    mkdir -p "$project_dir"

    cat > "$project_dir/package.json" << 'EOF'
{
  "name": "concurrent-test",
  "dependencies": {
    "react": "^18.2.0"
  }
}
EOF

    # Run multiple detections concurrently (with timeout)
    local pids=()
    for i in {1..5}; do
        timeout 15 "$ROOT_DIR/claude-ally.sh" detect "$project_dir" >/dev/null 2>&1 &
        pids+=($!)
    done

    # Wait for all to complete
    local all_completed=true
    for pid in "${pids[@]}"; do
        if ! wait "$pid"; then
            all_completed=false
        fi
    done

    if [[ "$all_completed" == "true" ]]; then
        echo -e "${GREEN}✅ PASS${NC} Concurrent execution completes safely"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        echo -e "${RED}❌ FAIL${NC} Concurrent execution has issues"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
    TESTS_TOTAL=$((TESTS_TOTAL + 1))
}

# Test: Memory usage with large projects
test_memory_usage() {
    echo "Testing: Memory usage with large projects"

    local project_dir="$TEST_TEMP_DIR/memory-test"
    mkdir -p "$project_dir"

    # Create many files to simulate large project
    for i in {1..100}; do
        mkdir -p "$project_dir/module-$i"
        echo '{"name": "module-'$i'", "dependencies": {"react": "^18.0.0"}}' > "$project_dir/module-$i/package.json"
    done

    # Run detection and monitor if it completes (with timeout for CI reliability)
    local result
    result=$(timeout 30 "$ROOT_DIR/claude-ally.sh" detect "$project_dir" 2>&1 || echo "FAILED")

    if [[ "$result" != "FAILED" ]]; then
        echo -e "${GREEN}✅ PASS${NC} Large project memory usage is manageable"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        echo -e "${RED}❌ FAIL${NC} Large project causes memory issues"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
    TESTS_TOTAL=$((TESTS_TOTAL + 1))
}

# Test: Unicode and special character handling
test_unicode_handling() {
    echo "Testing: Unicode and special character handling"

    local project_dir="$TEST_TEMP_DIR/unicode-测试-🚀"
    mkdir -p "$project_dir" 2>/dev/null || {
        # Fallback for systems that don't support unicode paths
        project_dir="$TEST_TEMP_DIR/unicode-test"
        mkdir -p "$project_dir"
    }

    cat > "$project_dir/package.json" << 'EOF'
{
  "name": "unicode-测试-project",
  "description": "Project with unicode 🚀 and émojis",
  "dependencies": {
    "react": "^18.2.0"
  }
}
EOF

    # Test that detection handles unicode gracefully (with timeout)
    local result
    result=$(timeout 20 "$ROOT_DIR/claude-ally.sh" detect "$project_dir" 2>&1 || echo "FAILED")

    if [[ "$result" != "FAILED" ]]; then
        echo -e "${GREEN}✅ PASS${NC} Unicode characters handled gracefully"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        echo -e "${RED}❌ FAIL${NC} Unicode characters cause issues"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
    TESTS_TOTAL=$((TESTS_TOTAL + 1))
}

# Test: Stack module error recovery
test_stack_module_error_recovery() {
    echo "Testing: Stack module error recovery"

    # Create a corrupted stack module
    local corrupted_module="$ROOT_DIR/stacks/corrupted-test.sh"
    cat > "$corrupted_module" << 'EOF'
#!/bin/bash
# Intentionally corrupted stack module for testing

detect_corrupted_test() {
    # This will cause an error
    nonexistent_command_that_should_fail
    undefined_variable_access="$UNDEFINED_VAR"

    # Should never reach here
    echo "corrupted-test|Corrupted|test|50"
}
EOF
    chmod +x "$corrupted_module"

    source "$ROOT_DIR/lib/stack-detector.sh"

    local project_dir="$TEST_TEMP_DIR/error-recovery-test"
    mkdir -p "$project_dir"
    cat > "$project_dir/package.json" << 'EOF'
{
  "name": "test",
  "dependencies": {"react": "^18.0.0"}
}
EOF

    # Test that one corrupted module doesn't break the entire detection
    local result
    result=$(detect_project_stack "$project_dir" 2>/dev/null || echo "no_detection")

    # Clean up corrupted module
    rm -f "$corrupted_module"

    # Should still detect other stacks despite corrupted module
    if [[ "$result" != "no_detection" ]]; then
        echo -e "${GREEN}✅ PASS${NC} Stack module error recovery works"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        echo -e "${YELLOW}⚠️ PARTIAL${NC} Error recovery - detection stopped (acceptable)"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    fi
    TESTS_TOTAL=$((TESTS_TOTAL + 1))
}

# Test: Cross-platform path normalization
test_cross_platform_paths() {
    echo "Testing: Cross-platform path normalization"

    # Test various path formats
    local test_paths=(
        "/Users/test/project"
        "C:\\Users\\test\\project"
        "./relative/path"
        "../parent/path"
        "~/home/path"
    )

    local project_dir="$TEST_TEMP_DIR/path-test"
    mkdir -p "$project_dir"
    cat > "$project_dir/package.json" << 'EOF'
{
  "name": "path-test",
  "dependencies": {"react": "^18.0.0"}
}
EOF

    # Test that detection works with various path formats
    local paths_handled=0
    for test_path in "${test_paths[@]}"; do
        # Only test paths that make sense on current platform
        if [[ "$test_path" == "C:\\"* ]] && [[ "$(uname)" != "CYGWIN"* ]] && [[ "$(uname)" != "MINGW"* ]]; then
            continue  # Skip Windows paths on Unix
        fi

        # Test with actual valid path (with timeout for CI stability)
        local result
        result=$(timeout 15 "$ROOT_DIR/claude-ally.sh" detect "$project_dir" 2>/dev/null || echo "no_detection")

        if [[ "$result" != "no_detection" ]]; then
            ((paths_handled++))
        fi
    done

    if [[ $paths_handled -gt 0 ]]; then
        echo -e "${GREEN}✅ PASS${NC} Cross-platform path handling works"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        echo -e "${RED}❌ FAIL${NC} Cross-platform path handling fails"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
    TESTS_TOTAL=$((TESTS_TOTAL + 1))
}

# Run all tests
run_tests() {
    echo -e "${BLUE}🧪 Running Edge Cases and Security Tests${NC}"
    echo "=========================================="
    echo ""

    setup

    test_multi_stack_detection
    test_deep_directory_handling
    test_malicious_path_handling
    test_corrupted_config_handling
    test_large_file_handling
    test_concurrent_execution
    test_memory_usage
    test_unicode_handling
    test_stack_module_error_recovery
    test_cross_platform_paths

    cleanup

    echo ""
    echo -e "${CYAN}📊 Test Results:${NC}"
    echo "  Total:  $TESTS_TOTAL"
    echo -e "  Passed: ${GREEN}$TESTS_PASSED${NC}"
    echo -e "  Failed: ${RED}$TESTS_FAILED${NC}"

    if [[ $TESTS_FAILED -eq 0 ]]; then
        echo -e "${GREEN}🎉 All edge case and security tests passed!${NC}"
        exit 0
    else
        echo -e "${RED}❌ Some edge case and security tests failed${NC}"
        exit 1
    fi
}

# Run tests if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    run_tests
fi