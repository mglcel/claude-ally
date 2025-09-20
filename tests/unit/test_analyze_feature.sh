#!/bin/bash
# Test the new analyze feature functionality

# Test configuration
TEST_NAME="Analyze Feature Tests"
TESTS_TOTAL=0
TESTS_PASSED=0
TESTS_FAILED=0

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

# Test helper functions

assert_contains() {
    local content="$1"
    local expected="$2"
    local test_name="$3"

    ((TESTS_TOTAL++))
    if [[ "$content" == *"$expected"* ]]; then
        echo -e "${GREEN}✅ PASS${NC} $test_name"
        ((TESTS_PASSED++))
    else
        echo -e "${RED}❌ FAIL${NC} $test_name"
        echo -e "   Expected to contain: ${YELLOW}$expected${NC}"
        echo -e "   Actual:              ${YELLOW}$content${NC}"
        ((TESTS_FAILED++))
    fi
}

# Setup
setup() {
    export CLAUDE_ALLY_TEST_MODE=true
    # Create temporary test project
    TEST_PROJECT_DIR=$(mktemp -d "/tmp/claude-ally-analyze-test-XXXXXX")
    cd "$TEST_PROJECT_DIR" || return

    # Create sample project structure
    echo '{"name": "test-project", "version": "1.0.0"}' > package.json
    echo "# Test Project" > README.md
    echo "node_modules/" > .gitignore
    mkdir -p src lib
    echo 'console.log("Hello");' > src/main.js

    # Initialize git
    git init --quiet 2>/dev/null || true
    git config user.name "Test User" 2>/dev/null || true
    git config user.email "test@example.com" 2>/dev/null || true
}

# Cleanup
cleanup() {
    if [[ -n "$TEST_PROJECT_DIR" ]] && [[ -d "$TEST_PROJECT_DIR" ]]; then
        rm -rf "$TEST_PROJECT_DIR"
    fi
}

# Test functions
test_analyze_basic_functionality() {
    echo "Testing: Basic analyze functionality"

    local output
    local exit_code
    output=$("$SCRIPT_DIR/claude-ally.sh" analyze "$TEST_PROJECT_DIR" 2>&1)
    exit_code=$?

    ((TESTS_TOTAL++))
    if [[ $exit_code -eq 0 ]]; then
        echo -e "${GREEN}✅ PASS${NC} Analyze command executes without error"
        ((TESTS_PASSED++))
    else
        echo -e "${RED}❌ FAIL${NC} Analyze command executes without error (exit code: $exit_code)"
        ((TESTS_FAILED++))
    fi

    assert_contains "$output" "Comprehensive Project Analysis" "Output contains analysis header"
    assert_contains "$output" "Project Information" "Output contains project info section"
    assert_contains "$output" "Technology Stack" "Output contains tech stack section"
    assert_contains "$output" "Project Structure" "Output contains structure section"
    assert_contains "$output" "Configuration Files" "Output contains config section"
    assert_contains "$output" "Claude Integration" "Output contains Claude status section"
}

test_analyze_project_detection() {
    echo "Testing: Project information detection"

    local output
    output=$("$SCRIPT_DIR/claude-ally.sh" analyze "$TEST_PROJECT_DIR" 2>&1)

    assert_contains "$output" "test-project" "Detects project name correctly"
    assert_contains "$output" "package.json" "Detects Node.js configuration file"
    assert_contains "$output" "Files:" "Shows file count"
    assert_contains "$output" "Directories:" "Shows directory count"
}

test_analyze_claude_status() {
    echo "Testing: Claude integration status detection"

    # Test without CLAUDE.md
    local output
    output=$("$SCRIPT_DIR/claude-ally.sh" analyze "$TEST_PROJECT_DIR" 2>&1)
    assert_contains "$output" "CLAUDE.md not found" "Detects missing CLAUDE.md"
    assert_contains "$output" "claude-ally setup" "Suggests setup command"

    # Test with CLAUDE.md
    echo "# Sample CLAUDE.md" > "$TEST_PROJECT_DIR/CLAUDE.md"
    echo "Some content here" >> "$TEST_PROJECT_DIR/CLAUDE.md"

    output=$("$SCRIPT_DIR/claude-ally.sh" analyze "$TEST_PROJECT_DIR" 2>&1)
    assert_contains "$output" "CLAUDE.md exists" "Detects existing CLAUDE.md"
    assert_contains "$output" "2 lines" "Shows correct line count"
}

test_analyze_current_directory() {
    echo "Testing: Analyze current directory"

    cd "$TEST_PROJECT_DIR" || return
    local output
    output=$("$SCRIPT_DIR/claude-ally.sh" analyze 2>&1)

    assert_contains "$output" "$(basename "$TEST_PROJECT_DIR")" "Analyzes current directory when no path specified"
}

test_analyze_git_integration() {
    echo "Testing: Git integration detection"

    cd "$TEST_PROJECT_DIR" || return
    git add . >/dev/null 2>&1
    git commit -m "Initial commit" >/dev/null 2>&1

    local output
    output=$("$SCRIPT_DIR/claude-ally.sh" analyze "$TEST_PROJECT_DIR" 2>&1)

    assert_contains "$output" "Git:" "Shows git information"
}

# Main test execution
main() {
    echo -e "${BLUE}🧪 Running Analyze Feature Unit Tests${NC}"
    echo "=============================================="
    echo ""

    setup

    test_analyze_basic_functionality
    test_analyze_project_detection
    test_analyze_claude_status
    test_analyze_current_directory
    test_analyze_git_integration

    cleanup

    echo ""
    echo -e "${CYAN}📊 Test Results:${NC}"
    echo "  Total:  $TESTS_TOTAL"
    echo "  Passed: ${GREEN}$TESTS_PASSED${NC}"
    echo "  Failed: ${RED}$TESTS_FAILED${NC}"

    if [[ $TESTS_FAILED -eq 0 ]]; then
        echo -e "${GREEN}🎉 All analyze feature tests passed!${NC}"
        exit 0
    else
        echo -e "${RED}❌ Some analyze feature tests failed${NC}"
        exit 1
    fi
}

# Run tests if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi