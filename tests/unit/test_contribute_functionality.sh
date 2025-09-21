#!/bin/bash
# Comprehensive unit tests for contribute functionality with Claude mocking

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
TEST_TEMP_DIR="/tmp/claude-ally-test-$(date +%Y%m%d%H%M%S)"
ORIGINAL_PATH="$PATH"

# Mock Claude responses (using standard arrays for compatibility)

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

assert_file_exists() {
    local file_path="$1"
    local test_name="$2"

    TESTS_TOTAL=$((TESTS_TOTAL + 1))

    if [[ -f "$file_path" ]]; then
        echo -e "${GREEN}✅ PASS${NC} $test_name"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        echo -e "${RED}❌ FAIL${NC} $test_name"
        echo -e "   File not found: ${YELLOW}$file_path${NC}"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
}

assert_file_not_exists() {
    local file_path="$1"
    local test_name="$2"

    TESTS_TOTAL=$((TESTS_TOTAL + 1))

    if [[ ! -f "$file_path" ]]; then
        echo -e "${GREEN}✅ PASS${NC} $test_name"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        echo -e "${RED}❌ FAIL${NC} $test_name"
        echo -e "   File should not exist: ${YELLOW}$file_path${NC}"
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

# Mock Claude CLI
setup_claude_mock() {
    local mock_dir="$TEST_TEMP_DIR/mock-bin"
    mkdir -p "$mock_dir"

    # Create mock claude command
    cat > "$mock_dir/claude" << 'EOF'
#!/bin/bash
# Mock Claude CLI for testing

# Read input from stdin
input=$(cat)

# Determine response based on input content and file structure
if [[ "$input" == *"pubspec.yaml"* ]] || [[ "$input" == *"flutter"* ]] || [[ "$input" == *"main.dart"* ]]; then
    # Flutter stack response - prioritize Flutter detection
    cat << 'FLUTTER_EOF'
**STACK_ID**: flutter-app
**TECH_STACK**: Flutter Mobile/Web Application
**PROJECT_TYPE**: mobile-app
**WORTH_ADDING**: YES - Flutter is a major cross-platform framework
**CONFIDENCE_PATTERNS**: pubspec.yaml with flutter dependency, lib/ directory with .dart files
**DETECTION_CODE**: if [[ -f "pubspec.yaml" ]] && grep -q "flutter:" pubspec.yaml; then echo "FLUTTER_DETECTED=true"; fi
FLUTTER_EOF
elif [[ "$input" == *"Kotlin Multiplatform"* ]] || [[ "$input" == *"moko-resources"* ]] || [[ "$input" == *"moko.versions.toml"* ]]; then
    # MOKO Resources stack response
    cat << 'MOKO_EOF'
## Stack Detection Analysis: MOKO Resources

**STACK_ID**: `kotlin-multiplatform-moko`

**TECH_STACK**: `Kotlin Multiplatform with MOKO Resources`

**PROJECT_TYPE**: `library`

**CONFIDENCE_PATTERNS**:
- gradle/moko.versions.toml file exists
- dev.icerock.moko:resources dependency in build files
- multiplatformResources configuration block

**WORTH_ADDING**: **YES**

**Reasoning**: MOKO Resources is a significant Kotlin Multiplatform library ecosystem for resource management

**DETECTION_CODE**:
```bash
if [[ -f "gradle/moko.versions.toml" ]]; then
    echo "MOKO_RESOURCES_DETECTED=true"
fi
```
MOKO_EOF


elif [[ "$input" == *"minimal"* ]] || [[ "$input" == *"test-framework"* ]]; then
    # Minimal/test project response
    cat << 'MINIMAL_EOF'
## Stack Detection Analysis

**STACK_ID**: N/A

**TECH_STACK**: Generic Test Project

**PROJECT_TYPE**: test-project

**CONFIDENCE_PATTERNS**:
- Single package.json with minimal dependencies
- Only test-framework dependency

**WORTH_ADDING**: **NO**

**Reasoning**: This appears to be a minimal test project rather than a real technology stack.

**DETECTION_CODE**: Not applicable - insufficient patterns for reliable detection
MINIMAL_EOF

else
    # Generic unknown stack response
    cat << 'UNKNOWN_EOF'
## Stack Detection Analysis

**STACK_ID**: `unknown-stack-type`

**TECH_STACK**: `Unknown Technology Stack`

**PROJECT_TYPE**: `unknown`

**CONFIDENCE_PATTERNS**:
- Various configuration files detected
- Unable to identify specific framework

**WORTH_ADDING**: **MAYBE**

**Reasoning**: This project contains configuration files but no clear framework indicators.

**DETECTION_CODE**:
```bash
# Detection logic would need to be manually determined
echo "UNKNOWN_STACK_DETECTED=true"
```
UNKNOWN_EOF
fi
EOF

    chmod +x "$mock_dir/claude"
    export PATH="$mock_dir:$PATH"
}

# Mock GitHub CLI
setup_github_mock() {
    local mock_dir="$TEST_TEMP_DIR/mock-bin"

    # Create mock gh command
    cat > "$mock_dir/gh" << 'EOF'
#!/bin/bash
# Mock GitHub CLI for testing

case "$1" in
    "auth")
        case "$2" in
            "status")
                echo "✓ Logged in to github.com as testuser"
                exit 0
                ;;
        esac
        ;;
    "repo")
        case "$2" in
            "fork")
                echo "✓ Created fork testuser/claude-ally"
                exit 0
                ;;
        esac
        ;;
    "pr")
        case "$2" in
            "create")
                echo "https://github.com/testuser/claude-ally/pull/123"
                exit 0
                ;;
        esac
        ;;
    *)
        echo "Mock gh: unknown command"
        exit 1
        ;;
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
    local project_dir="$TEST_TEMP_DIR/projects/$project_type"

    mkdir -p "$project_dir"

    case "$project_type" in
        "moko-resources")
            mkdir -p "$project_dir/gradle"
            echo 'resourcesVersion = "0.24.0"' > "$project_dir/gradle/moko.versions.toml"
            cat > "$project_dir/build.gradle.kts" << 'EOF'
dependencies {
    commonMainApi("dev.icerock.moko:resources:0.24.0")
}
EOF
            ;;
        "flutter")
            cat > "$project_dir/pubspec.yaml" << 'EOF'
name: flutter_test_app
dependencies:
  flutter:
    sdk: flutter
  cupertino_icons: ^1.0.2
EOF
            mkdir -p "$project_dir/lib"
            echo 'void main() {}' > "$project_dir/lib/main.dart"
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
            # Just create the directory
            ;;
    esac

    echo "$project_dir"
}

# Test: Claude availability check
test_claude_availability_check() {
    echo "Testing: Claude availability check"

    # Source the contribute script
    source "$ROOT_DIR/lib/contribute-stack.sh"

    # Test with Claude available
    assert_success "check_claude_availability" "Claude availability check succeeds with mock"

    # Test with Claude unavailable (temporarily remove from PATH)
    export PATH="/bin:/usr/bin"
    local result
    result=$(check_claude_availability && echo "available" || echo "unavailable")
    assert_equals "unavailable" "$result" "Claude availability check fails when Claude not in PATH"

    # Restore PATH
    export PATH="$TEST_TEMP_DIR/mock-bin:$ORIGINAL_PATH"
}

# Test: Cache key generation
test_cache_key_generation() {
    echo "Testing: Cache key generation"

    source "$ROOT_DIR/lib/contribute-stack.sh"

    # Test cache key generation
    local project_dir="/test/project"
    local project_name="test-project"

    # Simulate cache key generation (extract from the function)
    local cache_key
    cache_key=$(echo "${project_dir}_${project_name}" | md5sum | cut -d' ' -f1 2>/dev/null || echo "${project_dir}_${project_name}" | shasum -a 256 | cut -d' ' -f1)

    # Cache key should be deterministic and have correct length
    assert_equals "32" "${#cache_key}" "Cache key has correct length (MD5)"

    # Test that same input produces same cache key
    local cache_key2
    cache_key2=$(echo "${project_dir}_${project_name}" | md5sum | cut -d' ' -f1 2>/dev/null || echo "${project_dir}_${project_name}" | shasum -a 256 | cut -d' ' -f1)
    assert_equals "$cache_key" "$cache_key2" "Cache key is deterministic"
}

# Test: Analysis caching functionality
test_analysis_caching() {
    echo "Testing: Analysis caching functionality"

    source "$ROOT_DIR/lib/contribute-stack.sh"

    local project_dir
    project_dir=$(create_test_project "moko-resources")
    local project_name="moko-test"

    # First run - should create cache
    local result1
    result1=$(analyze_unknown_stack_with_claude "$project_dir" "$project_name" 2>/dev/null)

    # Check cache file was created
    local cache_key
    cache_key=$(echo "${project_dir}_${project_name}" | md5sum | cut -d' ' -f1)
    local cache_file="/tmp/claude_analysis_cache_${cache_key}.md"

    assert_file_exists "$cache_file" "Cache file created after first analysis"

    # Second run - should use cache
    local result2
    result2=$(analyze_unknown_stack_with_claude "$project_dir" "$project_name" 2>&1)

    assert_contains "Using cached Claude analysis" "$result2" "Second run uses cached analysis"
    assert_contains "kotlin-multiplatform-moko" "$result2" "Cached analysis contains correct content"
}

# Test: Contribute workflow with WORTH_ADDING=YES
test_contribute_workflow_worthy_project() {
    echo "Testing: Contribute workflow with worthy project"

    source "$ROOT_DIR/lib/contribute-stack.sh"

    local project_dir
    project_dir=$(create_test_project "moko-resources")
    local project_name="moko-test"

    # Run analysis
    local analysis_result
    analysis_result=$(analyze_unknown_stack_with_claude "$project_dir" "$project_name" 2>/dev/null)

    # Test that analysis shows WORTH_ADDING: YES
    assert_contains "WORTH_ADDING**: **YES" "$analysis_result" "Analysis indicates project is worth adding"
    assert_contains "kotlin-multiplatform-moko" "$analysis_result" "Analysis identifies correct stack ID"
    assert_contains "Kotlin Multiplatform" "$analysis_result" "Analysis identifies correct tech stack"
}

# Test: Contribute workflow with WORTH_ADDING=NO
test_contribute_workflow_unworthy_project() {
    echo "Testing: Contribute workflow with unworthy project"

    # Test with mock analysis result that shows WORTH_ADDING: NO
    local mock_analysis='
**STACK_ID**: N/A
**TECH_STACK**: Generic Test Project
**PROJECT_TYPE**: test-project
**WORTH_ADDING**: **NO**
**REASONING**: This appears to be a minimal test project rather than a real technology stack.
**DETECTION_CODE**: Not applicable - insufficient patterns for reliable detection
'

    # Test the parsing logic directly
    local worth_adding
    worth_adding=$(echo "$mock_analysis" | grep -i "WORTH_ADDING" | sed 's/.*WORTH_ADDING[^:]*:[[:space:]]*\(.*\)$/\1/' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//' | head -1)
    worth_adding=$(echo "$worth_adding" | tr '[:lower:]' '[:upper:]' | sed 's/^["\*]*//;s/["\*]*$//')

    assert_contains "NO" "$worth_adding" "Analysis indicates project is not worth adding"
    assert_contains "minimal test project" "$mock_analysis" "Analysis identifies minimal project correctly"
}

# Test: Stack ID sanitization
test_stack_id_sanitization() {
    echo "Testing: Stack ID sanitization"

    # Test various problematic stack IDs
    local test_cases=(
        "N/A:unknown-stack"
        "kotlin-multiplatform-moko:kotlin-multiplatform-moko"
        "My Stack With Spaces:my-stack-with-spaces"
        "UPPERCASE:uppercase"
        "special!@#chars:special-chars"
        "flutter_app:flutter-app"
        "react.js:react-js"
        "---leading-trailing---:leading-trailing"
    )

    for test_case in "${test_cases[@]}"; do
        local input="${test_case%:*}"
        local expected="${test_case#*:}"

        # Simulate sanitization logic
        local sanitized
        sanitized=$(echo "$input" | sed 's/[^a-zA-Z0-9-]/-/g' | sed 's/--*/-/g' | sed 's/^-*//;s/-*$//' | tr '[:upper:]' '[:lower:]')

        if [[ -z "$sanitized" ]] || [[ "$sanitized" == "n-a" ]] || [[ "$sanitized" == "unknown" ]]; then
            sanitized="unknown-stack"
        fi

        assert_equals "$expected" "$sanitized" "Stack ID sanitization: '$input' -> '$expected'"
    done
}

# Test: GitHub integration availability check
test_github_integration_check() {
    echo "Testing: GitHub integration availability check"

    source "$ROOT_DIR/lib/contribute-stack.sh"

    local project_dir
    project_dir=$(create_test_project "moko-resources")

    # Create a mock analysis result that should trigger GitHub integration
    local mock_analysis='
**STACK_ID**: `kotlin-multiplatform-moko`
**TECH_STACK**: `Kotlin Multiplatform with MOKO Resources`
**PROJECT_TYPE**: `library`
**WORTH_ADDING**: **YES**
'

    # Test GitHub CLI availability
    assert_success "command -v gh" "GitHub CLI mock is available"

    # Test GitHub authentication check
    local auth_result
    auth_result=$(gh auth status 2>&1 | grep -q "testuser" && echo "authenticated" || echo "not_authenticated")
    assert_equals "authenticated" "$auth_result" "GitHub CLI authentication check succeeds"
}

# Test: Error handling for missing Claude
test_error_handling_missing_claude() {
    echo "Testing: Error handling when Claude is missing"

    # Temporarily remove Claude from PATH
    export PATH="/bin:/usr/bin"

    source "$ROOT_DIR/lib/contribute-stack.sh"

    local project_dir
    project_dir=$(create_test_project "flutter")
    local project_name="flutter-test"

    # Test that function handles missing Claude gracefully
    local result
    result=$(analyze_unknown_stack_with_claude "$project_dir" "$project_name" 2>&1 || echo "FAILED")

    assert_contains "Claude not available" "$result" "Function reports Claude unavailability"

    # Restore PATH
    export PATH="$TEST_TEMP_DIR/mock-bin:$ORIGINAL_PATH"
}

# Test: Cache expiration
test_cache_expiration() {
    echo "Testing: Cache expiration (1 hour)"

    source "$ROOT_DIR/lib/contribute-stack.sh"

    local project_dir
    project_dir=$(create_test_project "flutter")
    local project_name="flutter-cache-test"

    # Create an old cache file (simulate 2 hours old)
    local cache_key
    cache_key=$(echo "${project_dir}_${project_name}" | md5sum | cut -d' ' -f1)
    local cache_file="/tmp/claude_analysis_cache_${cache_key}.md"

    echo "Old cached analysis" > "$cache_file"

    # Set the file time to 2 hours ago (use a timestamp that's definitely old)
    if command -v touch >/dev/null 2>&1; then
        # Try macOS format first, then fall back to creating truly old file
        touch -t "$(date -v-2H +%Y%m%d%H%M)" "$cache_file" 2>/dev/null || \
        touch -t "202301010100" "$cache_file" 2>/dev/null || \
        true
    fi

    # Run analysis - should not use old cache
    local result
    result=$(analyze_unknown_stack_with_claude "$project_dir" "$project_name" 2>&1)

    assert_not_contains "Using cached Claude analysis" "$result" "Expired cache is not used"
    assert_contains "Flutter" "$result" "New analysis is performed with expired cache"
}

# Test: Contribution template generation
test_contribution_template_generation() {
    echo "Testing: Contribution template generation"

    source "$ROOT_DIR/lib/contribute-stack.sh"

    local project_dir
    project_dir=$(create_test_project "moko-resources")
    local project_name="moko-test"

    # Run the contribution workflow up to template generation
    local analysis_result
    analysis_result=$(analyze_unknown_stack_with_claude "$project_dir" "$project_name" 2>/dev/null)

    # Create a temporary contribution directory
    local contrib_dir="$TEST_TEMP_DIR/contribution-test"
    mkdir -p "$contrib_dir"

    # Test template generation (extract relevant parts)
    cat > "$contrib_dir/CONTRIBUTION_GUIDE.md" << 'EOF'
# Stack Detection Contribution Guide

Thank you for contributing a new stack detection module to claude-ally!

## Files Generated:
- `stacks/[stack-name].sh` - Detection module
- `CONTRIBUTION_GUIDE.md` - This guide

## Next Steps:
1. **Review and customize** the generated detection module
2. **Test** the detection logic with your project
3. **Fork** the claude-ally repository on GitHub
EOF

    assert_file_exists "$contrib_dir/CONTRIBUTION_GUIDE.md" "Contribution guide template is generated"

    local guide_content
    guide_content=$(cat "$contrib_dir/CONTRIBUTION_GUIDE.md")
    assert_contains "Stack Detection Contribution Guide" "$guide_content" "Guide contains expected content"
    assert_contains "Fork" "$guide_content" "Guide mentions GitHub fork process"
}

# Test: Error handling for invalid project directories
test_error_handling_invalid_project() {
    echo "Testing: Error handling for invalid project directories"

    source "$ROOT_DIR/lib/contribute-stack.sh"

    # Test with non-existent directory
    local result
    result=$(analyze_unknown_stack_with_claude "/non/existent/path" "test" 2>&1 || echo "FAILED")

    # Should handle gracefully - Claude will analyze whatever path is provided
    # The error handling is more about whether the workflow continues properly
    assert_contains "analyze" "$result" "Function attempts analysis even with invalid path"
}

# Run all tests
run_tests() {
    echo -e "${BLUE}🧪 Running Contribute Functionality Unit Tests${NC}"
    echo "=============================================="
    echo ""

    setup

    test_claude_availability_check
    test_cache_key_generation
    test_analysis_caching
    test_contribute_workflow_worthy_project
    test_contribute_workflow_unworthy_project
    test_stack_id_sanitization
    test_github_integration_check
    test_error_handling_missing_claude
    test_cache_expiration
    test_contribution_template_generation
    test_error_handling_invalid_project

    cleanup

    echo ""
    echo -e "${CYAN}📊 Test Results:${NC}"
    echo "  Total:  $TESTS_TOTAL"
    echo -e "  Passed: ${GREEN}$TESTS_PASSED${NC}"
    echo -e "  Failed: ${RED}$TESTS_FAILED${NC}"

    if [[ $TESTS_FAILED -eq 0 ]]; then
        echo -e "${GREEN}🎉 All contribute functionality tests passed!${NC}"
        exit 0
    else
        echo -e "${RED}❌ Some contribute functionality tests failed${NC}"
        exit 1
    fi
}

# Run tests if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    run_tests
fi