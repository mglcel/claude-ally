#!/bin/bash
# Integration Tests for Contribute Workflow
# Tests the complete contribute workflow as executed in production

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
ORIGINAL_PATH="$PATH"
TESTS_TOTAL=0
TESTS_PASSED=0
TESTS_FAILED=0

# Test utilities
setup() {
    TEST_TEMP_DIR=$(mktemp -d -t claude-ally-integration-test-XXXXXX)

    # Setup mock environment that matches production
    setup_production_mock_environment

    echo -e "${BLUE}🧪 Running Contribute Integration Tests${NC}"
    echo "=============================================="
    echo ""
}

cleanup() {
    export PATH="$ORIGINAL_PATH"
    rm -rf "$TEST_TEMP_DIR" 2>/dev/null || true
    rm -f /tmp/claude_analysis_cache_* 2>/dev/null || true
    rm -f /tmp/claude_stack_analysis_* 2>/dev/null || true
    rm -f /tmp/stack_analysis_* 2>/dev/null || true
}

# Setup production-like mock environment
setup_production_mock_environment() {
    local mock_dir="$TEST_TEMP_DIR/mock-bin"
    mkdir -p "$mock_dir"

    # Create mock claude command that works in subprocess
    cat > "$mock_dir/claude" << 'EOF'
#!/bin/bash
# Production-like mock Claude CLI
input=$(cat)

# Determine response based on project files mentioned in input
if [[ "$input" == *"pubspec.yaml"* ]] || [[ "$input" == *"main.dart"* ]]; then
    cat << 'FLUTTER_EOF'
**STACK_ID**: flutter-app
**TECH_STACK**: Flutter Mobile Application
**PROJECT_TYPE**: mobile-app
**WORTH_ADDING**: YES - Flutter is a major cross-platform framework
**CONFIDENCE_PATTERNS**: pubspec.yaml, lib/*.dart files
**DETECTION_CODE**: if [[ -f "pubspec.yaml" ]] && grep -q "flutter:" pubspec.yaml; then echo "flutter-app"; fi
FLUTTER_EOF
elif [[ "$input" == *"gradle/libs.versions.toml"* ]] && [[ "$input" == *"iosApp"* ]] && [[ "$input" == *"composeApp"* ]]; then
    cat << 'KMP_EOF'
**STACK_ID**: kotlin-multiplatform-mobile
**TECH_STACK**: Kotlin Multiplatform Mobile with Compose
**PROJECT_TYPE**: mobile-app
**WORTH_ADDING**: YES - KMP is a major mobile development framework
**CONFIDENCE_PATTERNS**: gradle/libs.versions.toml, iosApp/, composeApp/, shared/
**DETECTION_CODE**: if [[ -f "gradle/libs.versions.toml" && -d "iosApp" && -d "composeApp" && -d "shared" ]]; then echo "kotlin-multiplatform-mobile"; fi
KMP_EOF
else
    cat << 'UNKNOWN_EOF'
**STACK_ID**: unknown-stack
**TECH_STACK**: Unknown Technology Stack
**PROJECT_TYPE**: unknown
**WORTH_ADDING**: NO - Unable to identify specific technology patterns
**CONFIDENCE_PATTERNS**: insufficient patterns detected
**DETECTION_CODE**: # No reliable detection patterns found
UNKNOWN_EOF
fi
EOF
    chmod +x "$mock_dir/claude"

    # Create mock gh CLI
    cat > "$mock_dir/gh" << 'EOF'
#!/bin/bash
case "$1" in
    "auth") echo "✓ Logged in to github.com as test-user" ;;
    "repo") echo "test-user/claude-ally" ;;
    *) echo "Mock gh command: $*" ;;
esac
EOF
    chmod +x "$mock_dir/gh"

    export PATH="$mock_dir:$PATH"
}

# Test project creation utilities
create_integration_test_project() {
    local project_type="$1"
    local project_dir="$TEST_TEMP_DIR/projects/$project_type"
    mkdir -p "$project_dir"

    case "$project_type" in
        "kotlin-multiplatform")
            # Create KMP project structure
            mkdir -p "$project_dir"/{gradle,iosApp,composeApp,shared}
            echo 'kotlin = "1.9.20"' > "$project_dir/gradle/libs.versions.toml"
            echo 'compose = "1.5.4"' >> "$project_dir/gradle/libs.versions.toml"
            echo '# iOS App' > "$project_dir/iosApp/README.md"
            echo '# Compose App' > "$project_dir/composeApp/README.md"
            echo '# Shared Code' > "$project_dir/shared/README.md"
            cat > "$project_dir/composeApp/google-services.json" << 'EOF'
{
  "project_info": {
    "project_number": "123456789",
    "project_id": "test-project"
  }
}
EOF
            ;;
        "flutter")
            # Create Flutter project structure
            mkdir -p "$project_dir/lib"
            cat > "$project_dir/pubspec.yaml" << 'EOF'
name: flutter_integration_test
dependencies:
  flutter:
    sdk: flutter
  cupertino_icons: ^1.0.2
EOF
            echo 'void main() { runApp(MyApp()); }' > "$project_dir/lib/main.dart"
            ;;
    esac

    echo "$project_dir"
}

# Test assertion utilities
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
        echo -e "   Actual output length: ${YELLOW}${#actual} chars${NC}"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
}

# Integration test: Complete contribute workflow execution
test_complete_contribute_workflow() {
    echo "Testing: Complete contribute workflow (production execution path)"

    local project_dir
    project_dir=$(create_integration_test_project "kotlin-multiplatform")

    # Test the complete workflow by calling claude-ally.sh exactly as users do
    local result
    result=$(cd "$project_dir" && echo -e "y\ny" | timeout 30 bash "$ROOT_DIR/claude-ally.sh" contribute 2>&1)

    # Verify key workflow stages completed
    assert_contains "🔍 Checking for contribution opportunities" "$result" "Contribution check initiated"
    assert_contains "🚀 Unknown stack detected" "$result" "Unknown stack detection works"
    assert_contains "🤖 Claude is available" "$result" "Claude availability check passes"

    # Should NOT contain the old error messages
    if [[ "$result" == *"command not found: create_cache_key"* ]]; then
        assert_failure "No utility function errors" "create_cache_key error still present"
    else
        assert_success "No utility function errors"
    fi

    if [[ "$result" == *"command not found: is_cache_valid"* ]]; then
        assert_failure "No cache validation errors" "is_cache_valid error still present"
    else
        assert_success "No cache validation errors"
    fi
}

# Integration test: Subprocess execution environment
test_subprocess_execution_environment() {
    echo "Testing: Subprocess execution environment (bash vs source)"

    local project_dir
    project_dir=$(create_integration_test_project "flutter")

    # Test subprocess execution (production method)
    local subprocess_result
    subprocess_result=$(cd "$project_dir" && bash "$ROOT_DIR/lib/contribute-stack.sh" "$project_dir" "flutter-test" "$ROOT_DIR" 2>&1 | head -20)

    # Should complete without command not found errors
    if [[ "$subprocess_result" == *"command not found"* ]]; then
        assert_failure "Subprocess execution works" "Command not found errors in subprocess"
    else
        assert_success "Subprocess execution works"
    fi

    # Test that utilities are accessible
    if [[ "$subprocess_result" == *"utilities.sh not found"* ]]; then
        assert_failure "Utilities available in subprocess" "utilities.sh sourcing failed"
    else
        assert_success "Utilities available in subprocess"
    fi
}

# Integration test: Dependency verification
test_dependency_verification() {
    echo "Testing: Dependency verification in production environment"

    # Test that contribute script can access required functions
    local test_script="$TEST_TEMP_DIR/test_deps.sh"
    cat > "$test_script" << 'EOF'
#!/bin/bash
source "$1/lib/contribute-stack.sh"

# Test utility functions are available
if type create_cache_key >/dev/null 2>&1; then
    echo "create_cache_key: AVAILABLE"
else
    echo "create_cache_key: MISSING"
fi

if type is_cache_valid >/dev/null 2>&1; then
    echo "is_cache_valid: AVAILABLE"
else
    echo "is_cache_valid: MISSING"
fi

# Test they actually work
test_key=$(create_cache_key "/test/path" "test-project" 2>&1)
if [[ "$test_key" =~ ^[a-f0-9]{32}$ ]] || [[ "$test_key" =~ ^[a-f0-9]{64}$ ]]; then
    echo "create_cache_key: FUNCTIONAL"
else
    echo "create_cache_key: NON_FUNCTIONAL ($test_key)"
fi
EOF

    local deps_result
    deps_result=$(bash "$test_script" "$ROOT_DIR" 2>&1)

    assert_contains "create_cache_key: AVAILABLE" "$deps_result" "create_cache_key function available"
    assert_contains "is_cache_valid: AVAILABLE" "$deps_result" "is_cache_valid function available"
    assert_contains "create_cache_key: FUNCTIONAL" "$deps_result" "create_cache_key function works"
}

# Integration test: Claude analysis in subprocess
test_claude_analysis_subprocess() {
    echo "Testing: Claude analysis execution in subprocess environment"

    local project_dir
    project_dir=$(create_integration_test_project "kotlin-multiplatform")

    # Test Claude analysis directly via subprocess
    local analysis_result
    analysis_result=$(cd "$project_dir" && bash -c "
        source '$ROOT_DIR/lib/contribute-stack.sh'
        analyze_unknown_stack_with_claude '$project_dir' 'kmp-test'
    " 2>&1)

    if [[ -n "$analysis_result" ]] && [[ "$analysis_result" != *"Failed to call Claude"* ]]; then
        assert_success "Claude analysis works in subprocess"
        assert_contains "STACK_ID" "$analysis_result" "Analysis contains stack identification"
        assert_contains "kotlin-multiplatform-mobile" "$analysis_result" "Correctly identifies KMP stack"
    else
        assert_failure "Claude analysis works in subprocess" "Analysis failed or empty"
    fi
}

# Integration test: End-to-end cache functionality
test_end_to_end_cache_functionality() {
    echo "Testing: End-to-end cache functionality in production environment"

    local project_dir
    project_dir=$(create_integration_test_project "flutter")

    # Clear any existing cache
    rm -f /tmp/claude_analysis_cache_* 2>/dev/null

    # First run - should create cache
    local first_result
    first_result=$(cd "$project_dir" && echo "n" | timeout 15 bash "$ROOT_DIR/claude-ally.sh" contribute 2>&1)

    # Second run - should use cache (if analysis succeeded)
    local second_result
    second_result=$(cd "$project_dir" && echo "n" | timeout 15 bash "$ROOT_DIR/claude-ally.sh" contribute 2>&1)

    # Check if cache files were created
    local cache_files
    cache_files=$(find /tmp -name "claude_analysis_cache_*" -mmin -2 2>/dev/null | wc -l)

    if [[ "$cache_files" -gt 0 ]]; then
        assert_success "Cache files created in production workflow"
    else
        assert_failure "Cache files created in production workflow" "No cache files found"
    fi
}

# Main test execution
main() {
    setup
    trap cleanup EXIT

    echo "🔧 Testing production execution paths and dependencies..."
    echo ""

    test_complete_contribute_workflow
    echo ""

    test_subprocess_execution_environment
    echo ""

    test_dependency_verification
    echo ""

    test_claude_analysis_subprocess
    echo ""

    test_end_to_end_cache_functionality
    echo ""

    # Test summary
    echo -e "${CYAN}📊 Integration Test Results:${NC}"
    echo "  Total:  $TESTS_TOTAL"
    echo -e "  Passed: ${GREEN}$TESTS_PASSED${NC}"
    echo -e "  Failed: ${RED}$TESTS_FAILED${NC}"

    if [[ $TESTS_FAILED -eq 0 ]]; then
        echo -e "${GREEN}🎉 All integration tests passed!${NC}"
        return 0
    else
        echo -e "${RED}❌ Some integration tests failed${NC}"
        return 1
    fi
}

# Run tests if called directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi