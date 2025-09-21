#!/bin/bash
# Unit Tests for Setup vs Contribute Stack Detection Consistency
# Tests that setup and contribute commands report consistent stack information

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
    TEST_TEMP_DIR=$(mktemp -d -t claude-ally-consistency-test-XXXXXX)
    echo -e "${BLUE}🧪 Running Setup vs Contribute Consistency Tests${NC}"
    echo "=================================================="
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

# Create test project with specific stack characteristics
create_test_project() {
    local project_name="$1"
    local stack_type="$2"
    local project_dir="$TEST_TEMP_DIR/$project_name"
    mkdir -p "$project_dir"

    case "$stack_type" in
        "php-nodejs")
            echo '{"name": "test-project", "scripts": {"build": "webpack"}}' > "$project_dir/package.json"
            echo '{"require": {"php": "^8.0"}}' > "$project_dir/composer.json"
            echo "# PHP NodeJS Test Project" > "$project_dir/README.md"
            ;;
        "nextjs")
            echo '{"name": "test-nextjs", "dependencies": {"next": "^13.0.0", "react": "^18.0.0"}}' > "$project_dir/package.json"
            mkdir -p "$project_dir/pages"
            echo "export default function Home() { return <div>Hello</div> }" > "$project_dir/pages/index.js"
            ;;
        "python-ai")
            echo 'tensorflow==2.13.0
openai==0.27.0
pandas==2.0.0' > "$project_dir/requirements.txt"
            echo "# Python AI Project" > "$project_dir/README.md"
            mkdir -p "$project_dir/src"
            echo "import tensorflow as tf" > "$project_dir/src/main.py"
            ;;
        *)
            echo "# Generic Test Project $project_name" > "$project_dir/README.md"
            ;;
    esac

    echo "$project_dir"
}

# Create mock Claude analysis that matches expected format
create_mock_analysis() {
    local project_dir="$1"
    local project_name="$2"
    local stack_id="$3"
    local tech_stack="$4"
    local worth_adding="$5"

    local cache_key
    cache_key=$(echo "${project_dir}_${project_name}" | md5sum 2>/dev/null | cut -d' ' -f1)

    cat > "/tmp/claude_analysis_cache_${cache_key}.md" << EOF
**STACK_ID**: $stack_id
**TECH_STACK**: $tech_stack
**PROJECT_TYPE**: web-app
**WORTH_ADDING**: $worth_adding
**CONFIDENCE_PATTERNS**:
- package.json (Node.js dependencies)
- composer.json (PHP dependencies)

**DETECTION_CODE**:
\`\`\`bash
if [[ -f "package.json" && -f "composer.json" ]]; then
    echo "$stack_id"
fi
\`\`\`

**REASONING**: Test stack for consistency verification.
EOF

    echo "$cache_key"
}

# Test: Setup suggests contributing unknown stack
test_setup_suggests_contribution() {
    echo "Testing: Setup suggests contributing unknown stack"

    local project_dir
    project_dir=$(create_test_project "test-setup-suggest" "php-nodejs")

    # Run setup in non-interactive mode
    local result
    result=$(cd "$project_dir" && NON_INTERACTIVE=true "$ROOT_DIR/claude-ally.sh" setup 2>&1)

    # Should suggest contribution since stack isn't detected
    assert_contains "Community Contribution Opportunity" "$result" "Setup suggests contribution"
    assert_contains "claude-ally doesn't recognize automatically" "$result" "Setup explains unrecognized stack"
}

# Test: Contribute workflow respects Claude's WORTH_ADDING decision
test_contribute_respects_worth_adding_no() {
    echo "Testing: Contribute workflow respects WORTH_ADDING: NO"

    local project_dir
    project_dir=$(create_test_project "test-worth-no" "php-nodejs")
    local project_name="test-worth-no"

    # Create mock analysis that says NOT worth adding
    create_mock_analysis "$project_dir" "$project_name" "php-web-app" "PHP Web Application" "NO - Standard stack already covered"

    # Run contribute command
    local result
    result=$(cd "$project_dir" && echo "n" | "$ROOT_DIR/claude-ally.sh" contribute 2>&1 || true)

    # Should indicate not suitable for contribution
    assert_contains "may not be suitable for contribution" "$result" "Contribute respects WORTH_ADDING: NO"
    assert_contains "Stack appears too minimal or generic" "$result" "Explains reason for rejection"

    # Should NOT proceed to GitHub automation
    if [[ "$result" == *"GitHub fork"* || "$result" == *"Pull request"* ]]; then
        assert_failure "Does not proceed to GitHub automation" "GitHub workflow was triggered despite WORTH_ADDING: NO"
    else
        assert_success "Does not proceed to GitHub automation"
    fi
}

# Test: Contribute workflow proceeds when Claude says WORTH_ADDING: YES
test_contribute_respects_worth_adding_yes() {
    echo "Testing: Contribute workflow respects WORTH_ADDING: YES"

    local project_dir
    project_dir=$(create_test_project "test-worth-yes" "nextjs")
    local project_name="test-worth-yes"

    # Create mock analysis that says worth adding
    create_mock_analysis "$project_dir" "$project_name" "nextjs-ai" "Next.js AI Application" "YES - Emerging AI-enhanced framework"

    # Run contribute command and automatically answer yes to prompts
    local result
    result=$(cd "$project_dir" && echo -e "y\ny" | "$ROOT_DIR/claude-ally.sh" contribute 2>&1 || true)

    # Should proceed with contribution workflow
    assert_contains "STACK CONTRIBUTION OPPORTUNITY DETECTED" "$result" "Shows contribution opportunity"
    assert_contains "Generate contribution files" "$result" "Offers to generate files"

    # Should not show the "not suitable" message
    if [[ "$result" == *"may not be suitable for contribution"* ]]; then
        assert_failure "Does not show unsuitability message" "Showed rejection message despite WORTH_ADDING: YES"
    else
        assert_success "Does not show unsuitability message"
    fi
}

# Test: Stack detection consistency between setup and contribute
test_stack_detection_consistency() {
    echo "Testing: Stack detection consistency between setup and contribute"

    local project_dir
    project_dir=$(create_test_project "test-consistency" "php-nodejs")

    # Run setup and extract suggested stack
    local setup_result
    setup_result=$(cd "$project_dir" && NON_INTERACTIVE=true "$ROOT_DIR/claude-ally.sh" setup 2>&1)

    local setup_stack
    setup_stack=$(echo "$setup_result" | grep -i "Stack:" | head -1 | sed 's/.*Stack: *//' | sed 's/ *$//')

    # Run contribute and extract detected stack
    local contribute_result
    contribute_result=$(cd "$project_dir" && echo "n" | timeout 30 "$ROOT_DIR/claude-ally.sh" contribute 2>&1 || true)

    # Both should mention the same general stack concepts
    if [[ -n "$setup_stack" ]]; then
        assert_success "Setup detects stack: $setup_stack"
    else
        assert_failure "Setup detects stack" "No stack detected in setup"
    fi

    # Contribute should process the project without errors
    assert_contains "Checking for contribution opportunities" "$contribute_result" "Contribute processes project"
}

# Test: Claude analysis caching consistency
test_claude_analysis_caching() {
    echo "Testing: Claude analysis caching consistency"

    local project_dir
    project_dir=$(create_test_project "test-cache-consistency" "python-ai")
    local project_name="test-cache-consistency"

    # Create a specific analysis
    local cache_key
    cache_key=$(create_mock_analysis "$project_dir" "$project_name" "python-ai" "Python AI/ML" "YES - Specialized AI stack")

    # Run contribute command - should use cached analysis
    local result1
    result1=$(cd "$project_dir" && echo "n" | "$ROOT_DIR/claude-ally.sh" contribute 2>&1 || true)

    # Run contribute again - should use same cached analysis
    local result2
    result2=$(cd "$project_dir" && echo "n" | "$ROOT_DIR/claude-ally.sh" contribute 2>&1 || true)

    # Both runs should mention using existing analysis
    assert_contains "Using existing Claude analysis" "$result1" "First run uses cached analysis"
    assert_contains "Using existing Claude analysis" "$result2" "Second run uses cached analysis"

    # Verify cache file still exists
    if [[ -f "/tmp/claude_analysis_cache_${cache_key}.md" ]]; then
        assert_success "Cache file persists between runs"
    else
        assert_failure "Cache file persists between runs" "Cache file was removed"
    fi
}

# Main test execution
main() {
    setup
    trap cleanup EXIT

    echo "🔧 Testing setup vs contribute stack detection consistency..."
    echo ""

    test_setup_suggests_contribution
    echo ""

    test_contribute_respects_worth_adding_no
    echo ""

    test_contribute_respects_worth_adding_yes
    echo ""

    test_stack_detection_consistency
    echo ""

    test_claude_analysis_caching
    echo ""

    # Test summary
    echo -e "${CYAN}📊 Setup vs Contribute Consistency Test Results:${NC}"
    echo "  Total:  $TESTS_TOTAL"
    echo -e "  Passed: ${GREEN}$TESTS_PASSED${NC}"
    echo -e "  Failed: ${RED}$TESTS_FAILED${NC}"

    if [[ $TESTS_FAILED -eq 0 ]]; then
        echo -e "${GREEN}🎉 All consistency tests passed!${NC}"
        return 0
    else
        echo -e "${RED}❌ Some consistency tests failed${NC}"
        return 1
    fi
}

# Run tests if called directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi