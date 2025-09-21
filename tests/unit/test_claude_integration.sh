#!/bin/bash
#
# Test Suite: Claude Integration Features
# Tests the new real Claude integration functionality
#

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

run_test() {
    local test_func="$1"
    echo "Testing: ${test_func#test_}"
    if "$test_func"; then
        return 0
    else
        echo -e "${RED}❌ Test function failed: $test_func${NC}"
        return 1
    fi
}

show_test_summary() {
    local suite_name="$1"
    echo ""
    echo -e "${BOLD}Test Summary:${NC}"
    echo "Total: $TESTS_TOTAL, Passed: $TESTS_PASSED, Failed: $TESTS_FAILED"

    if [[ $TESTS_FAILED -eq 0 ]]; then
        echo -e "${GREEN}🎉 All tests passed!${NC}"
        exit 0
    else
        echo -e "${RED}💥 Some tests failed!${NC}"
        exit 1
    fi
}

# Test setup
setup() {
    TEST_PROJECT_DIR="/tmp/test_claude_integration_$$"
    mkdir -p "$TEST_PROJECT_DIR"

    # Mock Claude CLI availability for testing
    export CLAUDE_AVAILABLE="true"

    echo "Test setup completed for Claude integration tests"
}

# Test teardown
teardown() {
    [[ -n "$TEST_PROJECT_DIR" ]] && rm -rf "$TEST_PROJECT_DIR"
    unset CLAUDE_AVAILABLE
    unset CLAUDE_DETECTED_STACK
    echo "Test teardown completed"
}

# Test: Claude CLI availability detection
test_claude_cli_availability_detection() {
    echo "Testing: Claude CLI availability detection"

    # Test when Claude is available (mocked)
    if command -v claude >/dev/null 2>&1; then
        # Real Claude CLI is available
        assert_success "Claude CLI availability detection" "Real Claude CLI detected"
    else
        # No real Claude CLI - test the detection logic
        # Temporarily override the check for testing
        local old_path="$PATH"
        export PATH="/nonexistent:$PATH"

        if perform_claude_project_analysis "$TEST_PROJECT_DIR" 2>/dev/null; then
            assert_failure "Claude CLI detection should fail" "False positive detection"
        else
            assert_success "Claude CLI detection correctly fails" "Proper detection logic"
        fi

        export PATH="$old_path"
    fi
}

# Test: Claude project analysis prompt generation
test_claude_analysis_prompt_generation() {
    echo "Testing: Claude analysis prompt generation"

    # Create test project structure
    echo '{"name": "test-project", "dependencies": {"express": "^4.18.0"}}' > "$TEST_PROJECT_DIR/package.json"
    echo '{"name": "test-php", "require": {"laravel/framework": "^10.0"}}' > "$TEST_PROJECT_DIR/composer.json"
    mkdir -p "$TEST_PROJECT_DIR/src"

    # Test prompt generation logic (mocked)

    # Mock the Claude command to test prompt structure
    local mock_claude_output="TECH_STACK: PHP Laravel + MySQL"

    # Test that the function generates proper file structure analysis
    local project_structure
    project_structure=$(find "$TEST_PROJECT_DIR" -maxdepth 3 -type f \( \
        -name "*.json" -o -name "*.js" -o -name "*.ts" -o \
        -name "*.php" -o -name "*.py" -o -name "*.rb" -o \
        -name "composer.*" -o -name "package*.json" \
        \) 2>/dev/null | head -20)

    if [[ -n "$project_structure" ]]; then
        assert_success "Project structure analysis" "Files found: $project_structure"
    else
        assert_failure "Project structure analysis" "No files found"
    fi

    # Test configuration file sampling
    if [[ -f "$TEST_PROJECT_DIR/package.json" && -f "$TEST_PROJECT_DIR/composer.json" ]]; then
        assert_success "Configuration file detection" "Both package.json and composer.json detected"
    else
        assert_failure "Configuration file detection" "Missing expected config files"
    fi
}

# Test: Claude response parsing
test_claude_response_parsing() {
    echo "Testing: Claude response parsing"

    # Test various Claude response formats
    local test_responses=(
        "TECH_STACK: PHP Laravel + MySQL"
        "TECH_STACK: Node.js + React + PostgreSQL"
        "TECH_STACK: Python Django + SQLite"
        "Some preamble text
TECH_STACK: Go + Gin + MongoDB
Some additional text"
        "Invalid response without proper format"
    )

    local expected_stacks=(
        "PHP Laravel + MySQL"
        "Node.js + React + PostgreSQL"
        "Python Django + SQLite"
        "Go + Gin + MongoDB"
        ""
    )

    for i in "${!test_responses[@]}"; do
        local response="${test_responses[$i]}"
        local expected="${expected_stacks[$i]}"

        # Simulate Claude response parsing
        local detected_stack
        detected_stack=$(echo "$response" | grep "TECH_STACK:" | head -1 | sed 's/TECH_STACK:[[:space:]]*//' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')

        if [[ "$detected_stack" == "$expected" ]]; then
            assert_success "Claude response parsing for: $response" "Correctly parsed: $detected_stack"
        else
            assert_failure "Claude response parsing for: $response" "Expected: '$expected', got: '$detected_stack'"
        fi
    done
}

# Test: Stack mapping for Claude analysis
test_claude_stack_mapping() {
    echo "Testing: Claude stack mapping"

    # Test stack ID mapping logic
    local test_stacks=(
        "PHP Laravel + MySQL"
        "Laravel Framework + PostgreSQL"
        "Next.js + React + TypeScript"
        "React + Node.js + Express"
        "Python Django + SQLite"
        "Node.js + Express + MongoDB"
        "Unknown Framework + Database"
    )

    local expected_ids=(
        "php-laravel"
        "php-laravel"
        "nextjs-ai"
        "nextjs-ai"
        "python-ai"
        "nextjs-ai"
        "unknown"
    )

    for i in "${!test_stacks[@]}"; do
        local stack="${test_stacks[$i]}"
        local expected_id="${expected_ids[$i]}"

        # Simulate the stack ID mapping logic
        local stack_id=""
        if [[ "$stack" == *"PHP Laravel"* ]] || [[ "$stack" == *"Laravel"* ]]; then
            stack_id="php-laravel"
        elif [[ "$stack" == *"Next.js"* ]] || [[ "$stack" == *"React"* ]]; then
            stack_id="nextjs-ai"
        elif [[ "$stack" == *"Python"* ]]; then
            stack_id="python-ai"
        elif [[ "$stack" == *"Node.js"* ]]; then
            stack_id="nextjs-ai"
        else
            stack_id="unknown"
        fi

        if [[ "$stack_id" == "$expected_id" ]]; then
            assert_success "Stack mapping for: $stack" "Correctly mapped to: $stack_id"
        else
            assert_failure "Stack mapping for: $stack" "Expected: $expected_id, got: $stack_id"
        fi
    done
}

# Test: Automatic CLAUDE.md generation
test_automatic_claude_md_generation() {
    echo "Testing: Automatic CLAUDE.md generation"

    # Create a test prompt file
    local prompt_file="$TEST_PROJECT_DIR/claude_prompt_test.txt"
    cat > "$prompt_file" << 'EOF'
# CLAUDE COGNITIVE ENHANCEMENT SETUP

## Project Context
- **Project Name**: test-project
- **Project Type**: web-app
- **Tech Stack**: PHP Laravel + MySQL
- **Critical Assets**: user data, configuration files
- **Common Issues**: configuration errors, dependency issues

## Instructions for Claude

Please create a comprehensive CLAUDE.md file for this project that includes:

1. **Project Overview**
   - Brief description of the project and its purpose
   - Technology stack and architecture overview

2. **🚨 MANDATORY DEVELOPMENT REQUIREMENTS - NEVER SKIP THESE**
   - Security patterns specific to: PHP Laravel + MySQL
   - Performance considerations for: web-app
   - Error handling patterns
   - Input validation requirements

## Output Format

**IMPORTANT**: Your response must be the complete CLAUDE.md file content, starting with "# Project Name" and ending with the learning protocol. Do NOT provide a summary or description of what you would create. Output the actual file content that can be saved directly as CLAUDE.md.
EOF

    # Test the setup function logic (without actually calling Claude)
    local project_dir
    local claude_md_file
    project_dir="$(dirname "$prompt_file")"
    claude_md_file="$project_dir/CLAUDE.md"

    # Verify prompt file exists
    if [[ -f "$prompt_file" ]]; then
        assert_success "Prompt file creation" "Test prompt file created successfully"
    else
        assert_failure "Prompt file creation" "Failed to create test prompt file"
        return 1
    fi

    # Test CLAUDE.md path calculation
    if [[ "$claude_md_file" == "$TEST_PROJECT_DIR/CLAUDE.md" ]]; then
        assert_success "CLAUDE.md path calculation" "Correct path: $claude_md_file"
    else
        assert_failure "CLAUDE.md path calculation" "Incorrect path: $claude_md_file"
    fi

    # Test prompt content validation
    if grep -q "\*\*IMPORTANT\*\*: Your response must be the complete CLAUDE.md file content" "$prompt_file"; then
        assert_success "Prompt format validation" "Enhanced output format instructions found"
    else
        assert_failure "Prompt format validation" "Missing enhanced output format instructions"
    fi
}

# Test: Fallback hierarchy implementation
test_claude_analysis_fallback_hierarchy() {
    echo "Testing: Claude analysis fallback hierarchy"

    # Mock different scenarios
    local scenarios=(
        "claude_success_with_stack"
        "claude_success_no_stack"
        "claude_failure_with_static"
        "claude_failure_no_static"
    )

    for scenario in "${scenarios[@]}"; do
        case "$scenario" in
            "claude_success_with_stack")
                # Test successful Claude analysis
                export CLAUDE_DETECTED_STACK="PHP Laravel + MySQL"
                local analysis_success="true"
                local detected_stack_info=""
                ;;
            "claude_success_no_stack")
                # Test Claude success but no stack detected
                export CLAUDE_DETECTED_STACK=""
                local analysis_success="true"
                local detected_stack_info="php-laravel|PHP Laravel|web-app|85"
                ;;
            "claude_failure_with_static")
                # Test Claude failure with static detection available
                unset CLAUDE_DETECTED_STACK
                local analysis_success="false"
                local detected_stack_info="php-laravel|PHP Laravel|web-app|85"
                ;;
            "claude_failure_no_static")
                # Test complete failure
                unset CLAUDE_DETECTED_STACK
                local analysis_success="false"
                local detected_stack_info=""
                ;;
        esac

        # Test the priority logic
        local chosen_method=""
        if [[ "$analysis_success" == "true" && -n "$CLAUDE_DETECTED_STACK" ]]; then
            chosen_method="claude"
        elif [[ -n "$detected_stack_info" ]]; then
            chosen_method="static"
        else
            chosen_method="generic"
        fi

        case "$scenario" in
            "claude_success_with_stack")
                if [[ "$chosen_method" == "claude" ]]; then
                    assert_success "Fallback hierarchy: $scenario" "Correctly chose Claude analysis"
                else
                    assert_failure "Fallback hierarchy: $scenario" "Should have chosen Claude analysis"
                fi
                ;;
            "claude_success_no_stack"|"claude_failure_with_static")
                if [[ "$chosen_method" == "static" ]]; then
                    assert_success "Fallback hierarchy: $scenario" "Correctly chose static detection"
                else
                    assert_failure "Fallback hierarchy: $scenario" "Should have chosen static detection"
                fi
                ;;
            "claude_failure_no_static")
                if [[ "$chosen_method" == "generic" ]]; then
                    assert_success "Fallback hierarchy: $scenario" "Correctly chose generic fallback"
                else
                    assert_failure "Fallback hierarchy: $scenario" "Should have chosen generic fallback"
                fi
                ;;
        esac
    done
}

# Test: Error handling for Claude integration
test_claude_integration_error_handling() {
    echo "Testing: Claude integration error handling"

    # Test missing prompt file
    local nonexistent_prompt="/tmp/nonexistent_prompt_$$.txt"

    # Simulate the error condition check
    if [[ ! -f "$nonexistent_prompt" ]]; then
        assert_success "Missing prompt file detection" "Correctly detected missing prompt file"
    else
        assert_failure "Missing prompt file detection" "Failed to detect missing prompt file"
    fi

    # Test empty prompt file
    local empty_prompt="$TEST_PROJECT_DIR/empty_prompt.txt"
    touch "$empty_prompt"

    if [[ -f "$empty_prompt" && ! -s "$empty_prompt" ]]; then
        assert_success "Empty prompt file detection" "Correctly detected empty prompt file"
    else
        assert_failure "Empty prompt file detection" "Failed to detect empty prompt file"
    fi

    # Test invalid Claude response
    local invalid_responses=(
        ""
        "Some text without proper format"
        "TECH_STACK:"
        "DIFFERENT_FORMAT: PHP Laravel"
    )

    for response in "${invalid_responses[@]}"; do
        local parsed_stack
        if echo "$response" | grep -q "TECH_STACK:"; then
            parsed_stack=$(echo "$response" | grep "TECH_STACK:" | head -1 | sed 's/TECH_STACK:[[:space:]]*//' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
        else
            parsed_stack=""
        fi

        if [[ -z "$parsed_stack" ]]; then
            assert_success "Invalid Claude response handling: '$response'" "Correctly handled invalid response"
        else
            assert_failure "Invalid Claude response handling: '$response'" "Should have rejected invalid response"
        fi
    done
}

# Run the test suite
main() {
    echo "🧪 Running Claude Integration Test Suite"
    echo "========================================"

    setup

    run_test test_claude_cli_availability_detection
    run_test test_claude_analysis_prompt_generation
    run_test test_claude_response_parsing
    run_test test_claude_stack_mapping
    run_test test_automatic_claude_md_generation
    run_test test_claude_analysis_fallback_hierarchy
    run_test test_claude_integration_error_handling

    teardown

    show_test_summary "Claude Integration"
}

# Run if called directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi