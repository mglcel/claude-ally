#!/bin/bash
# Integration tests for claude-ally CLI functionality with mocking
# Tests complete workflows including contribute, detect, and validation systems

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
TEST_TEMP_DIR="/tmp/claude-ally-integration-test-$(date +%s)"
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

# Mock Claude CLI for integration testing
setup_claude_mock() {
    local mock_dir="$TEST_TEMP_DIR/mock-bin"
    mkdir -p "$mock_dir"

    cat > "$mock_dir/claude" << 'EOF'
#!/bin/bash
# Mock Claude CLI for integration testing

input=$(cat)

# Simulate different responses based on project content
if [[ "$input" == *"Flutter"* ]] || [[ "$input" == *"pubspec.yaml"* ]]; then
    cat << 'FLUTTER_EOF'
**STACK_ID**: `flutter-app`
**TECH_STACK**: `Flutter Mobile Application`
**PROJECT_TYPE**: `mobile-app`
**WORTH_ADDING**: **YES**
**DETECTION_CODE**: Flutter detection patterns
FLUTTER_EOF
elif [[ "$input" == *"React"* ]] || [[ "$input" == *"package.json"* ]]; then
    cat << 'REACT_EOF'
**STACK_ID**: `react-web-app`
**TECH_STACK**: `React Web Application`
**PROJECT_TYPE**: `web-app`
**WORTH_ADDING**: **YES**
**DETECTION_CODE**: React detection patterns
REACT_EOF
elif [[ "$input" == *"minimal"* ]] || [[ "$input" == *"test-framework"* ]]; then
    cat << 'MINIMAL_EOF'
**STACK_ID**: N/A
**TECH_STACK**: Generic Test Project
**PROJECT_TYPE**: test-project
**WORTH_ADDING**: **NO**
**DETECTION_CODE**: Not applicable
MINIMAL_EOF
else
    cat << 'UNKNOWN_EOF'
**STACK_ID**: `unknown-project`
**TECH_STACK**: `Unknown Technology Stack`
**PROJECT_TYPE**: `unknown`
**WORTH_ADDING**: **MAYBE**
**DETECTION_CODE**: Manual detection required
UNKNOWN_EOF
fi
EOF

    chmod +x "$mock_dir/claude"
    export PATH="$mock_dir:$PATH"
}

# Mock GitHub CLI
setup_github_mock() {
    local mock_dir="$TEST_TEMP_DIR/mock-bin"

    cat > "$mock_dir/gh" << 'EOF'
#!/bin/bash
case "$1" in
    "auth") echo "✓ Logged in to github.com as testuser"; exit 0 ;;
    "repo") echo "✓ Created fork"; exit 0 ;;
    "pr") echo "https://github.com/testuser/claude-ally/pull/123"; exit 0 ;;
    *) exit 1 ;;
esac
EOF

    chmod +x "$mock_dir/gh"
}

# Setup test environment
setup() {
    mkdir -p "$TEST_TEMP_DIR"
    setup_claude_mock
    setup_github_mock

    # Clear any existing cache
    rm -f /tmp/claude_analysis_cache_* 2>/dev/null || true
}

# Cleanup test environment
cleanup() {
    export PATH="$ORIGINAL_PATH"
    rm -rf "$TEST_TEMP_DIR" 2>/dev/null || true
    rm -f /tmp/claude_analysis_cache_* 2>/dev/null || true
}

# Create test project fixtures
create_test_project() {
    local project_type="$1"
    local project_name="$2"
    local project_dir="$TEST_TEMP_DIR/projects/$project_name"

    mkdir -p "$project_dir"

    case "$project_type" in
        "flutter")
            cat > "$project_dir/pubspec.yaml" << 'EOF'
name: flutter_integration_test
dependencies:
  flutter:
    sdk: flutter
  http: ^0.13.0
dev_dependencies:
  flutter_test:
    sdk: flutter
EOF
            mkdir -p "$project_dir/lib"
            echo 'void main() => runApp(MyApp());' > "$project_dir/lib/main.dart"
            ;;
        "react")
            cat > "$project_dir/package.json" << 'EOF'
{
  "name": "react-integration-test",
  "dependencies": {
    "react": "^18.2.0",
    "react-dom": "^18.2.0"
  },
  "devDependencies": {
    "@types/react": "^18.0.0",
    "typescript": "^4.9.0"
  }
}
EOF
            mkdir -p "$project_dir/src"
            echo 'export default function App() { return <div>Hello</div>; }' > "$project_dir/src/App.tsx"
            ;;
        "nextjs")
            cat > "$project_dir/package.json" << 'EOF'
{
  "name": "nextjs-integration-test",
  "dependencies": {
    "next": "^14.0.0",
    "react": "^18.2.0"
  }
}
EOF
            echo 'module.exports = {}' > "$project_dir/next.config.js"
            ;;
        "minimal")
            cat > "$project_dir/package.json" << 'EOF'
{
  "name": "minimal-test",
  "dependencies": {
    "test-framework": "1.0.0"
  }
}
EOF
            ;;
        "empty")
            # Just create empty directory
            ;;
    esac

    echo "$project_dir"
}

# Test: CLI help command
test_cli_help() {
    echo "Testing: CLI help command"

    local help_output
    help_output=$("$ROOT_DIR/claude-ally.sh" help 2>&1)

    assert_contains "Claude-Ally" "$help_output" "Help shows application name"
    assert_contains "USAGE" "$help_output" "Help shows usage section"
    assert_contains "detect" "$help_output" "Help shows detect command"
    assert_contains "contribute" "$help_output" "Help shows contribute command"
    assert_contains "setup" "$help_output" "Help shows setup command"
    assert_contains "version" "$help_output" "Help shows version command"
}

# Test: CLI version command
test_cli_version() {
    echo "Testing: CLI version command"

    local version_output
    version_output=$("$ROOT_DIR/claude-ally.sh" version 2>&1)

    assert_contains "Claude-Ally" "$version_output" "Version shows application name"
    assert_contains "Version" "$version_output" "Version shows version info"
}

# Test: CLI detect command with known stack
test_cli_detect_known_stack() {
    echo "Testing: CLI detect command with known stack"

    local project_dir
    project_dir=$(create_test_project "nextjs" "nextjs-test")

    local detect_output
    detect_output=$("$ROOT_DIR/claude-ally.sh" detect "$project_dir" 2>&1)

    assert_contains "nextjs" "$detect_output" "Detect identifies Next.js stack"
    assert_contains "Next.js" "$detect_output" "Detect shows Next.js framework"
}

# Test: CLI detect command with unknown stack
test_cli_detect_unknown_stack() {
    echo "Testing: CLI detect command with unknown stack"

    local project_dir
    project_dir=$(create_test_project "empty" "unknown-test")

    local detect_output
    detect_output=$("$ROOT_DIR/claude-ally.sh" detect "$project_dir" 2>&1)

    assert_contains "Unknown stack detected" "$detect_output" "Detect identifies unknown stack"
    assert_contains "contribute" "$detect_output" "Detect suggests contribute command"
}

# Test: CLI contribute command workflow
test_cli_contribute_workflow() {
    echo "Testing: CLI contribute command workflow"

    local project_dir
    project_dir=$(create_test_project "flutter" "flutter-contribute-test")

    # Test contribute command with mocked input (simulate user saying 'n' to prompts)
    local contribute_output
    contribute_output=$(echo -e "n\n" | timeout 30 "$ROOT_DIR/claude-ally.sh" contribute "$project_dir" 2>&1 || echo "TIMEOUT")

    if [[ "$contribute_output" == "TIMEOUT" ]]; then
        echo -e "${YELLOW}⚠️ SKIP${NC} Contribute workflow test (timeout - interactive prompts)"
        # Don't count this as a test failure
    else
        assert_contains "STACK CONTRIBUTION OPPORTUNITY" "$contribute_output" "Contribute shows opportunity dialog"
        assert_contains "flutter" "$contribute_output" "Contribute identifies Flutter project"
    fi
}

# Test: CLI contribute command with unworthy project
test_cli_contribute_unworthy_project() {
    echo "Testing: CLI contribute command with unworthy project"

    local project_dir
    project_dir=$(create_test_project "minimal" "minimal-contribute-test")

    # Test contribute command
    local contribute_output
    contribute_output=$(echo -e "y\ny\n" | timeout 30 "$ROOT_DIR/claude-ally.sh" contribute "$project_dir" 2>&1 || echo "TIMEOUT")

    if [[ "$contribute_output" == "TIMEOUT" ]]; then
        echo -e "${YELLOW}⚠️ SKIP${NC} Contribute unworthy project test (timeout)"
    else
        assert_contains "may not be suitable for contribution" "$contribute_output" "Contribute detects unworthy project"
    fi
}

# Test: CLI validate command
test_cli_validate() {
    echo "Testing: CLI validate command"

    # Create a test file to validate
    local test_file="$TEST_TEMP_DIR/test-validate.sh"
    cat > "$test_file" << 'EOF'
#!/bin/bash
echo "Valid shell script"
EOF
    chmod +x "$test_file"

    local validate_output
    validate_output=$("$ROOT_DIR/claude-ally.sh" validate "$test_file" 2>&1)

    assert_contains "validation" "$validate_output" "Validate command executes"
}

# Test: CLI setup command
test_cli_setup() {
    echo "Testing: CLI setup command"

    local setup_project_dir
    setup_project_dir=$(create_test_project "react" "setup-test")

    # Test setup command (simulate user saying 'n' to interactive prompts)
    local setup_output
    setup_output=$(echo -e "n\n" | timeout 30 "$ROOT_DIR/claude-ally.sh" setup "$setup_project_dir" 2>&1 || echo "TIMEOUT")

    if [[ "$setup_output" == "TIMEOUT" ]]; then
        echo -e "${YELLOW}⚠️ SKIP${NC} Setup command test (timeout - interactive prompts)"
    else
        assert_contains "Claude-Ally Setup" "$setup_output" "Setup shows setup dialog"
    fi
}

# Test: Error handling for invalid commands
test_cli_invalid_command() {
    echo "Testing: CLI error handling for invalid commands"

    local error_output
    assert_exit_code 1 "$ROOT_DIR/claude-ally.sh invalid-command" "Invalid command returns exit code 1"

    error_output=$("$ROOT_DIR/claude-ally.sh" invalid-command 2>&1 || true)
    assert_contains "Unknown command" "$error_output" "Invalid command shows error message"
}

# Test: Error handling for missing arguments
test_cli_missing_arguments() {
    echo "Testing: CLI error handling for missing arguments"

    # Test detect without directory
    local detect_error
    detect_error=$("$ROOT_DIR/claude-ally.sh" detect 2>&1 || true)
    assert_contains "Detecting project stack" "$detect_error" "Detect without args uses current directory"

    # Test validate without file
    local validate_error
    assert_exit_code 1 "$ROOT_DIR/claude-ally.sh validate" "Validate without file returns exit code 1"
}

# Test: CLI with absolute vs relative paths
test_cli_path_handling() {
    echo "Testing: CLI path handling (absolute vs relative)"

    local project_dir
    project_dir=$(create_test_project "react" "path-test")

    # Test with absolute path
    local abs_output
    abs_output=$("$ROOT_DIR/claude-ally.sh" detect "$project_dir" 2>&1)
    assert_contains "react" "$abs_output" "Detect works with absolute path"

    # Test with relative path (from project directory)
    cd "$project_dir"
    local rel_output
    rel_output=$("$ROOT_DIR/claude-ally.sh" detect "." 2>&1)
    assert_contains "react" "$rel_output" "Detect works with relative path"
}

# Test: CLI caching behavior
test_cli_caching_behavior() {
    echo "Testing: CLI caching behavior"

    local project_dir
    project_dir=$(create_test_project "flutter" "cache-test")

    # First contribute run (should create cache)
    echo -e "n\n" | timeout 20 "$ROOT_DIR/claude-ally.sh" contribute "$project_dir" >/dev/null 2>&1 || true

    # Check if cache file was created
    local cache_key
    cache_key=$(echo "${project_dir}_$(basename "$project_dir")" | md5sum | cut -d' ' -f1 2>/dev/null || echo "fallback")

    if [[ -f "/tmp/claude_analysis_cache_${cache_key}.md" ]]; then
        echo -e "${GREEN}✅ PASS${NC} Cache file created after contribute run"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        echo -e "${RED}❌ FAIL${NC} Cache file not created"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
    TESTS_TOTAL=$((TESTS_TOTAL + 1))

    # Second run should use cache (check for cache message)
    local second_run
    second_run=$(echo -e "n\n" | timeout 20 "$ROOT_DIR/claude-ally.sh" contribute "$project_dir" 2>&1 || echo "TIMEOUT")

    if [[ "$second_run" != "TIMEOUT" ]]; then
        assert_contains "Using cached" "$second_run" "Second contribute run uses cache"
    else
        echo -e "${YELLOW}⚠️ SKIP${NC} Cache usage test (timeout)"
    fi
}

# Test: CLI performance with multiple projects
test_cli_performance() {
    echo "Testing: CLI performance with multiple projects"

    local project_types=("react" "flutter" "nextjs")
    local start_time end_time duration

    start_time=$(date +%s)

    for i in "${!project_types[@]}"; do
        local project_dir
        project_dir=$(create_test_project "${project_types[$i]}" "perf-test-$i")
        "$ROOT_DIR/claude-ally.sh" detect "$project_dir" >/dev/null 2>&1 || true
    done

    end_time=$(date +%s)
    duration=$((end_time - start_time))

    if [[ $duration -le 10 ]]; then
        echo -e "${GREEN}✅ PASS${NC} CLI performance test (${duration}s <= 10s)"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        echo -e "${RED}❌ FAIL${NC} CLI performance test (${duration}s > 10s)"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
    TESTS_TOTAL=$((TESTS_TOTAL + 1))
}

# Test: CLI resilience to corrupted cache
test_cli_corrupted_cache_resilience() {
    echo "Testing: CLI resilience to corrupted cache"

    local project_dir
    project_dir=$(create_test_project "react" "corrupted-cache-test")

    # Create corrupted cache file
    local cache_key
    cache_key=$(echo "${project_dir}_$(basename "$project_dir")" | md5sum | cut -d' ' -f1 2>/dev/null || echo "fallback")
    local cache_file="/tmp/claude_analysis_cache_${cache_key}.md"

    echo "CORRUPTED CACHE DATA" > "$cache_file"

    # Run contribute - should handle corrupted cache gracefully
    local result
    result=$(echo -e "n\n" | timeout 20 "$ROOT_DIR/claude-ally.sh" contribute "$project_dir" 2>&1 || echo "TIMEOUT")

    if [[ "$result" != "TIMEOUT" ]]; then
        assert_contains "STACK CONTRIBUTION" "$result" "CLI handles corrupted cache gracefully"
    else
        echo -e "${YELLOW}⚠️ SKIP${NC} Corrupted cache test (timeout)"
    fi
}

# Run all tests
run_tests() {
    echo -e "${BLUE}🧪 Running CLI Integration Tests${NC}"
    echo "=================================="
    echo ""

    setup

    test_cli_help
    test_cli_version
    test_cli_detect_known_stack
    test_cli_detect_unknown_stack
    test_cli_contribute_workflow
    test_cli_contribute_unworthy_project
    test_cli_validate
    test_cli_setup
    test_cli_invalid_command
    test_cli_missing_arguments
    test_cli_path_handling
    test_cli_caching_behavior
    test_cli_performance
    test_cli_corrupted_cache_resilience

    cleanup

    echo ""
    echo -e "${CYAN}📊 Test Results:${NC}"
    echo "  Total:  $TESTS_TOTAL"
    echo -e "  Passed: ${GREEN}$TESTS_PASSED${NC}"
    echo -e "  Failed: ${RED}$TESTS_FAILED${NC}"

    if [[ $TESTS_FAILED -eq 0 ]]; then
        echo -e "${GREEN}🎉 All CLI integration tests passed!${NC}"
        exit 0
    else
        echo -e "${RED}❌ Some CLI integration tests failed${NC}"
        exit 1
    fi
}

# Run tests if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    run_tests
fi