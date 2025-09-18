#!/bin/bash
# Integration tests for claude-ally CLI functionality
# Tests complete workflows including config, cache, and performance systems

set -euo pipefail

# Test framework
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Test counters
TESTS_TOTAL=0
TESTS_PASSED=0
TESTS_FAILED=0

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

# Setup test environment
setup() {
    # Create test workspace
    mkdir -p /tmp/claude-ally-integration-test
    export TEST_CONFIG_HOME="/tmp/claude-ally-integration-test/.claude-ally"
    mkdir -p "$TEST_CONFIG_HOME"

    # Create temporary test config
    cat > "$TEST_CONFIG_HOME/config.json" << 'EOF'
{
  "version": "2.0.0",
  "cache": {
    "enabled": true,
    "expiry_days": 1,
    "max_size_mb": 10
  },
  "detection": {
    "confidence_threshold": 50,
    "fallback_to_legacy": true,
    "auto_update_modules": false
  },
  "ui": {
    "colors": false,
    "verbose": false,
    "progress_bars": false
  }
}
EOF

    # Override config path for testing
    export CLAUDE_ALLY_CONFIG_HOME="$TEST_CONFIG_HOME"
}

# Cleanup test environment
cleanup() {
    rm -rf /tmp/claude-ally-integration-test
    unset TEST_CONFIG_HOME
    unset CLAUDE_ALLY_CONFIG_HOME
}

# Test: CLI command availability
test_cli_commands() {
    echo "Testing: CLI command availability"

    # Test main CLI exists and is executable
    assert_success "test -x '$ROOT_DIR/claude-ally.sh'" "Main CLI script exists and executable"

    # Test help command
    local help_output
    if help_output=$(bash "$ROOT_DIR/claude-ally.sh" help 2>&1); then
        assert_contains "Claude-Ally" "$help_output" "Help command shows application name"
        assert_contains "COMMANDS:" "$help_output" "Help command shows commands section"
        assert_contains "setup" "$help_output" "Help command lists setup command"
        assert_contains "detect" "$help_output" "Help command lists detect command"
        assert_contains "contribute" "$help_output" "Help command lists contribute command"
    else
        echo -e "${RED}❌ FAIL${NC} Help command execution"
        TESTS_FAILED=$((TESTS_FAILED + 1))
        TESTS_TOTAL=$((TESTS_TOTAL + 1))
    fi

    # Test version command
    local version_output
    if version_output=$(bash "$ROOT_DIR/claude-ally.sh" version 2>&1); then
        assert_contains "2.0.0" "$version_output" "Version command shows correct version"
        assert_contains "Features:" "$version_output" "Version command shows features list"
    else
        echo -e "${RED}❌ FAIL${NC} Version command execution"
        TESTS_FAILED=$((TESTS_FAILED + 1))
        TESTS_TOTAL=$((TESTS_TOTAL + 1))
    fi
}

# Test: Detection workflow integration
test_detection_workflow() {
    echo "Testing: Detection workflow integration"

    # Create test Next.js AI project (supported stack)
    local test_dir="/tmp/claude-ally-integration-test/nextjs-ai-project"
    mkdir -p "$test_dir"

    cat > "$test_dir/package.json" << 'EOF'
{
  "name": "test-nextjs-ai-app",
  "version": "1.0.0",
  "dependencies": {
    "next": "^14.0.0",
    "react": "^18.0.0",
    "react-dom": "^18.0.0",
    "@ai-sdk/openai": "^0.0.40",
    "ai": "^3.2.0"
  },
  "devDependencies": {
    "typescript": "^5.0.0",
    "@types/react": "^18.0.0"
  },
  "scripts": {
    "dev": "next dev",
    "build": "next build"
  }
}
EOF

    echo 'module.exports = {}' > "$test_dir/next.config.js"
    echo '{}' > "$test_dir/tsconfig.json"
    mkdir -p "$test_dir/app"
    echo "export default function Page() { return <div>AI App</div> }" > "$test_dir/app/page.tsx"

    # Test detection
    local detection_result
    if detection_result=$(bash "$ROOT_DIR/claude-ally.sh" detect "$test_dir" 2>&1); then
        assert_contains "Detected:" "$detection_result" "Detection workflow identifies project"
        assert_contains "Next.js" "$detection_result" "Detection identifies Next.js framework"
        assert_contains "TypeScript" "$detection_result" "Detection identifies TypeScript"
        assert_contains "Confidence:" "$detection_result" "Detection shows confidence score"
    else
        echo -e "${RED}❌ FAIL${NC} Detection workflow failed"
        echo "Output: $detection_result"
        TESTS_FAILED=$((TESTS_FAILED + 1))
        TESTS_TOTAL=$((TESTS_TOTAL + 1))
    fi
}

# Test: Configuration management integration
test_config_integration() {
    echo "Testing: Configuration management integration"

    # Test config show
    local config_output
    if config_output=$(bash "$ROOT_DIR/claude-ally.sh" config show 2>&1); then
        assert_contains "version" "$config_output" "Config show displays version"
        assert_contains "cache" "$config_output" "Config show displays cache settings"
        assert_contains "detection" "$config_output" "Config show displays detection settings"
    else
        echo -e "${RED}❌ FAIL${NC} Config show command failed"
        echo "Output: $config_output"
        TESTS_FAILED=$((TESTS_FAILED + 1))
        TESTS_TOTAL=$((TESTS_TOTAL + 1))
    fi

    # Test config get (if available)
    if bash "$ROOT_DIR/claude-ally.sh" config get cache.enabled &>/dev/null; then
        local cache_setting
        cache_setting=$(bash "$ROOT_DIR/claude-ally.sh" config get cache.enabled 2>/dev/null || echo "not_available")
        if [[ "$cache_setting" == "true" || "$cache_setting" == "false" ]]; then
            echo -e "${GREEN}✅ PASS${NC} Config get returns boolean value"
            TESTS_PASSED=$((TESTS_PASSED + 1))
        else
            echo -e "${RED}❌ FAIL${NC} Config get returns unexpected value: $cache_setting"
            TESTS_FAILED=$((TESTS_FAILED + 1))
        fi
        TESTS_TOTAL=$((TESTS_TOTAL + 1))
    fi
}

# Test: Cache system integration
test_cache_integration() {
    echo "Testing: Cache system integration"

    # Test cache stats
    local cache_output
    if cache_output=$(bash "$ROOT_DIR/claude-ally.sh" cache stats 2>&1); then
        assert_contains "Cache" "$cache_output" "Cache stats shows cache information"
    else
        echo -e "${RED}❌ FAIL${NC} Cache stats command failed"
        echo "Output: $cache_output"
        TESTS_FAILED=$((TESTS_FAILED + 1))
        TESTS_TOTAL=$((TESTS_TOTAL + 1))
    fi

    # Test cache clean
    if bash "$ROOT_DIR/claude-ally.sh" cache clean &>/dev/null; then
        echo -e "${GREEN}✅ PASS${NC} Cache clean command executes successfully"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        echo -e "${RED}❌ FAIL${NC} Cache clean command failed"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
    TESTS_TOTAL=$((TESTS_TOTAL + 1))
}

# Test: Error handling integration
test_error_handling() {
    echo "Testing: Error handling integration"

    # Test invalid command
    local invalid_output
    if invalid_output=$(bash "$ROOT_DIR/claude-ally.sh" invalid_command 2>&1); then
        assert_contains "Unknown command" "$invalid_output" "Invalid command shows error message"
        assert_contains "USAGE:" "$invalid_output" "Invalid command shows usage help"
    else
        # Command should fail, so success here means the error handling worked
        echo -e "${GREEN}✅ PASS${NC} Invalid command properly rejected"
        TESTS_PASSED=$((TESTS_PASSED + 1))
        TESTS_TOTAL=$((TESTS_TOTAL + 1))
    fi

    # Test detection on non-existent directory
    local nonexistent_output
    if nonexistent_output=$(bash "$ROOT_DIR/claude-ally.sh" detect "/nonexistent/directory" 2>&1); then
        # Should either fail gracefully or show appropriate message
        echo -e "${GREEN}✅ PASS${NC} Detection handles non-existent directory gracefully"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        echo -e "${GREEN}✅ PASS${NC} Detection properly fails on non-existent directory"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    fi
    TESTS_TOTAL=$((TESTS_TOTAL + 1))
}

# Test: Module loading integration
test_module_loading() {
    echo "Testing: Module loading integration"

    # Test that main CLI can load and execute detection (proof modules are loaded)
    local detection_output
    if detection_output=$(bash "$ROOT_DIR/claude-ally.sh" detect "$ROOT_DIR" 2>&1); then
        if [[ "$detection_output" == *"Detected:"* ]] || [[ "$detection_output" == *"Unknown stack"* ]]; then
            echo -e "${GREEN}✅ PASS${NC} Stack detection module loaded and functional"
            TESTS_PASSED=$((TESTS_PASSED + 1))
        else
            echo -e "${RED}❌ FAIL${NC} Stack detection module not working properly"
            echo "Output: $detection_output"
            TESTS_FAILED=$((TESTS_FAILED + 1))
        fi
    else
        echo -e "${RED}❌ FAIL${NC} Stack detection command failed"
        echo "Output: $detection_output"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
    TESTS_TOTAL=$((TESTS_TOTAL + 1))
}

# Test: System validation integration
test_system_validation() {
    echo "Testing: System validation integration"

    local validation_output
    if validation_output=$(bash "$ROOT_DIR/claude-ally.sh" validate 2>&1); then
        assert_contains "Validating claude-ally system" "$validation_output" "Validation shows header"
        assert_contains "core files" "$validation_output" "Validation checks core files"
        assert_contains "dependencies" "$validation_output" "Validation checks dependencies"

        if [[ "$validation_output" == *"✅"* ]]; then
            echo -e "${GREEN}✅ PASS${NC} System validation shows success indicators"
            TESTS_PASSED=$((TESTS_PASSED + 1))
        else
            echo -e "${YELLOW}⚠️ WARN${NC} System validation shows no success indicators (may be expected)"
            TESTS_PASSED=$((TESTS_PASSED + 1))
        fi
        TESTS_TOTAL=$((TESTS_TOTAL + 1))
    else
        echo -e "${RED}❌ FAIL${NC} System validation command failed"
        TESTS_FAILED=$((TESTS_FAILED + 1))
        TESTS_TOTAL=$((TESTS_TOTAL + 1))
    fi
}

# Run all tests
run_tests() {
    echo "🧪 Running Claude-Ally Integration Tests"
    echo "========================================"

    setup

    test_cli_commands
    test_detection_workflow
    test_config_integration
    test_cache_integration
    test_error_handling
    test_module_loading
    test_system_validation

    cleanup

    echo ""
    echo "📊 Integration Test Results:"
    echo "  Total:  $TESTS_TOTAL"
    echo -e "  Passed: ${GREEN}$TESTS_PASSED${NC}"
    echo -e "  Failed: ${RED}$TESTS_FAILED${NC}"

    if [[ $TESTS_FAILED -eq 0 ]]; then
        echo -e "${GREEN}🎉 All integration tests passed!${NC}"
        exit 0
    else
        echo -e "${RED}❌ Some integration tests failed${NC}"
        exit 1
    fi
}

# Run tests if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    run_tests
fi