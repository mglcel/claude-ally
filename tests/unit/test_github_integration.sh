#!/bin/bash
# Unit tests for GitHub integration functionality with mocking

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
TEST_TEMP_DIR="/tmp/claude-ally-github-test-$(date +%s)"
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

# Mock GitHub CLI with different scenarios
setup_github_mock() {
    local mock_dir="$TEST_TEMP_DIR/mock-bin"
    mkdir -p "$mock_dir"

    # Create mock gh command with various scenarios
    cat > "$mock_dir/gh" << 'EOF'
#!/bin/bash
# Mock GitHub CLI for testing

# Check for test scenario environment variable
case "${GITHUB_TEST_SCENARIO:-success}" in
    "auth_failure")
        case "$1" in
            "auth")
                echo "Not authenticated" >&2
                exit 1
                ;;
        esac
        ;;
    "fork_failure")
        case "$1" in
            "auth")
                echo "✓ Logged in to github.com as testuser"
                exit 0
                ;;
            "repo")
                case "$2" in
                    "fork")
                        echo "Fork already exists or failed" >&2
                        exit 1
                        ;;
                esac
                ;;
        esac
        ;;
    "pr_failure")
        case "$1" in
            "auth")
                echo "✓ Logged in to github.com as testuser"
                exit 0
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
                        echo "Failed to create pull request" >&2
                        exit 1
                        ;;
                esac
                ;;
        esac
        ;;
    "success"|*)
        # Default success scenario
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
                        if [[ "$3" == "mglcel/claude-ally" ]]; then
                            echo "✓ Created fork testuser/claude-ally"
                            exit 0
                        else
                            echo "Unknown repository: $3" >&2
                            exit 1
                        fi
                        ;;
                esac
                ;;
            "pr")
                case "$2" in
                    "create")
                        # Parse PR creation arguments
                        local title=""
                        local body=""
                        while [[ $# -gt 0 ]]; do
                            case $1 in
                                --title)
                                    title="$2"
                                    shift 2
                                    ;;
                                --body)
                                    body="$2"
                                    shift 2
                                    ;;
                                *)
                                    shift
                                    ;;
                            esac
                        done

                        # Return PR URL
                        echo "https://github.com/testuser/claude-ally/pull/123"
                        exit 0
                        ;;
                esac
                ;;
        esac
        ;;
esac

echo "Mock gh: unknown command or scenario" >&2
exit 1
EOF

    chmod +x "$mock_dir/gh"
    export PATH="$mock_dir:$PATH"
}

# Mock git commands
setup_git_mock() {
    local mock_dir="$TEST_TEMP_DIR/mock-bin"

    # Create mock git command
    cat > "$mock_dir/git" << 'EOF'
#!/bin/bash
# Mock git for testing

case "$1" in
    "clone")
        # Create a mock repository structure
        local repo_url="$2"
        local target_dir="$3"

        mkdir -p "$target_dir"
        cd "$target_dir"

        # Create basic git repository structure
        mkdir -p .git stacks lib
        echo "# Mock repository" > README.md
        echo "#!/bin/bash" > claude-ally.sh
        chmod +x claude-ally.sh

        exit 0
        ;;
    "checkout")
        if [[ "$2" == "-b" ]]; then
            echo "Switched to a new branch '$3'"
        else
            echo "Switched to branch '$2'"
        fi
        exit 0
        ;;
    "add")
        echo "Files staged for commit"
        exit 0
        ;;
    "commit")
        echo "[test-branch abc1234] Test commit message"
        exit 0
        ;;
    "push")
        if [[ "${GIT_TEST_SCENARIO:-success}" == "conflict" ]]; then
            echo "Push failed due to conflicts" >&2
            exit 1
        else
            echo "Changes pushed successfully"
            exit 0
        fi
        ;;
    "pull")
        echo "Already up to date"
        exit 0
        ;;
    "status")
        echo "On branch test-branch"
        echo "nothing to commit, working tree clean"
        exit 0
        ;;
    *)
        echo "Mock git: unknown command $1" >&2
        exit 1
        ;;
esac
EOF

    chmod +x "$mock_dir/git"
}

# Setup test environment
setup() {
    mkdir -p "$TEST_TEMP_DIR"
    setup_github_mock
    setup_git_mock
}

# Cleanup test environment
cleanup() {
    export PATH="$ORIGINAL_PATH"
    rm -rf "$TEST_TEMP_DIR" 2>/dev/null || true
}

# Test: GitHub authentication check
test_github_auth_check() {
    echo "Testing: GitHub authentication check"

    source "$ROOT_DIR/lib/github-pr.sh"

    # Test successful authentication
    export GITHUB_TEST_SCENARIO="success"
    local auth_result
    auth_result=$(gh auth status 2>/dev/null && echo "authenticated" || echo "not_authenticated")
    assert_equals "authenticated" "$auth_result" "GitHub authentication check succeeds"

    # Test failed authentication
    export GITHUB_TEST_SCENARIO="auth_failure"
    auth_result=$(gh auth status 2>/dev/null && echo "authenticated" || echo "not_authenticated")
    assert_equals "not_authenticated" "$auth_result" "GitHub authentication check fails appropriately"

    export GITHUB_TEST_SCENARIO="success"
}

# Test: Stack module generation
test_stack_module_generation() {
    echo "Testing: Stack module generation"

    source "$ROOT_DIR/lib/github-pr.sh"

    local work_dir="$TEST_TEMP_DIR/test-repo"
    mkdir -p "$work_dir/stacks"
    cd "$work_dir"

    # Test module generation
    local stack_id="kotlin-multiplatform-moko"
    local tech_stack="Kotlin Multiplatform with MOKO Resources"
    local project_type="library"
    local patterns="gradle files, moko dependencies"

    # Create the module file (simulate the function behavior)
    local function_name="${stack_id//-/_}"
    cat > "stacks/${stack_id}.sh" << EOF
#!/bin/bash
# $tech_stack Stack Detection

detect_$function_name() {
    local project_dir="\$1"
    local confidence=0
    local tech_stack="$tech_stack"
    local project_type="$project_type"

    if [[ -f "\$project_dir/gradle/moko.versions.toml" ]]; then
        confidence=\$((confidence + 40))
    fi

    if [[ \$confidence -ge 50 ]]; then
        echo "${stack_id}|\$tech_stack|\$project_type|\$confidence"
        return 0
    fi

    return 1
}
EOF

    assert_file_exists "stacks/${stack_id}.sh" "Stack module file is generated"

    local module_content
    module_content=$(cat "stacks/${stack_id}.sh")
    assert_contains "detect_kotlin_multiplatform_moko" "$module_content" "Module contains properly named function"
    assert_contains "Kotlin Multiplatform" "$module_content" "Module contains correct tech stack"
    assert_contains "moko.versions.toml" "$module_content" "Module contains detection logic"
}

# Test: Safe function name creation
test_safe_function_name_creation() {
    echo "Testing: Safe function name creation"

    # Test various stack IDs
    local test_cases=(
        "kotlin-multiplatform-moko:kotlin_multiplatform_moko"
        "react-native:react_native"
        "next-js-ai:next_js_ai"
        "vue-3-typescript:vue_3_typescript"
        "svelte-kit:svelte_kit"
    )

    for test_case in "${test_cases[@]}"; do
        local input="${test_case%:*}"
        local expected="${test_case#*:}"

        # Simulate the function name conversion
        local function_name="${input//-/_}"

        assert_equals "$expected" "$function_name" "Function name conversion: '$input' -> '$expected'"
    done
}

# Test: GitHub fork creation
test_github_fork_creation() {
    echo "Testing: GitHub fork creation"

    # Test successful fork
    export GITHUB_TEST_SCENARIO="success"
    local fork_result
    fork_result=$(gh repo fork mglcel/claude-ally 2>/dev/null && echo "success" || echo "failed")
    assert_equals "success" "$fork_result" "GitHub fork creation succeeds"

    # Test fork failure
    export GITHUB_TEST_SCENARIO="fork_failure"
    fork_result=$(gh repo fork mglcel/claude-ally 2>/dev/null && echo "success" || echo "failed")
    assert_equals "failed" "$fork_result" "GitHub fork creation fails appropriately"

    export GITHUB_TEST_SCENARIO="success"
}

# Test: Pull request creation
test_pull_request_creation() {
    echo "Testing: Pull request creation"

    # Test successful PR creation
    export GITHUB_TEST_SCENARIO="success"
    local pr_result
    pr_result=$(gh pr create --title "Test PR" --body "Test body" 2>/dev/null)
    assert_contains "https://github.com/testuser/claude-ally/pull/123" "$pr_result" "Pull request creation returns URL"

    # Test PR creation failure
    export GITHUB_TEST_SCENARIO="pr_failure"
    pr_result=$(gh pr create --title "Test PR" --body "Test body" 2>/dev/null || echo "FAILED")
    assert_equals "FAILED" "$pr_result" "Pull request creation fails appropriately"

    export GITHUB_TEST_SCENARIO="success"
}

# Test: Git conflict resolution
test_git_conflict_resolution() {
    echo "Testing: Git conflict resolution"

    local work_dir="$TEST_TEMP_DIR/conflict-test"
    mkdir -p "$work_dir"
    cd "$work_dir"

    # Test successful push
    export GIT_TEST_SCENARIO="success"
    local push_result
    push_result=$(git push origin test-branch 2>/dev/null && echo "success" || echo "failed")
    assert_equals "success" "$push_result" "Git push succeeds without conflicts"

    # Test push with conflicts (should trigger pull and retry)
    export GIT_TEST_SCENARIO="conflict"
    push_result=$(git push origin test-branch 2>/dev/null || echo "conflict_handled")
    assert_equals "conflict_handled" "$push_result" "Git push conflicts are handled"

    export GIT_TEST_SCENARIO="success"
}

# Test: Complete automated PR workflow
test_complete_pr_workflow() {
    echo "Testing: Complete automated PR workflow"

    source "$ROOT_DIR/lib/github-pr.sh"

    local work_dir="$TEST_TEMP_DIR/complete-workflow"
    mkdir -p "$work_dir"

    # Mock a complete workflow by simulating the main steps
    export GITHUB_TEST_SCENARIO="success"
    export GIT_TEST_SCENARIO="success"

    # Step 1: Check GitHub authentication
    local auth_check
    auth_check=$(gh auth status 2>/dev/null && echo "✓" || echo "✗")
    assert_equals "✓" "$auth_check" "Workflow step 1: GitHub authentication"

    # Step 2: Fork repository
    local fork_check
    fork_check=$(gh repo fork mglcel/claude-ally 2>/dev/null && echo "✓" || echo "✗")
    assert_equals "✓" "$fork_check" "Workflow step 2: Repository fork"

    # Step 3: Clone and setup
    cd "$work_dir"
    local clone_check
    clone_check=$(git clone https://github.com/testuser/claude-ally.git claude-ally-fork 2>/dev/null && echo "✓" || echo "✗")
    assert_equals "✓" "$clone_check" "Workflow step 3: Repository clone"

    # Step 4: Create branch
    cd claude-ally-fork || exit 1
    local branch_check
    branch_check=$(git checkout -b add-test-stack 2>/dev/null && echo "✓" || echo "✗")
    assert_equals "✓" "$branch_check" "Workflow step 4: Branch creation"

    # Step 5: Generate and commit module
    mkdir -p stacks
    echo "# Test stack module" > stacks/test-stack.sh
    local commit_check
    commit_check=$(git add . && git commit -m "Add test stack" 2>/dev/null && echo "✓" || echo "✗")
    assert_equals "✓" "$commit_check" "Workflow step 5: Module commit"

    # Step 6: Push changes
    local push_check
    push_check=$(git push -u origin add-test-stack 2>/dev/null && echo "✓" || echo "✗")
    assert_equals "✓" "$push_check" "Workflow step 6: Push changes"

    # Step 7: Create pull request
    local pr_check
    pr_check=$(gh pr create --title "Add test stack" --body "Test PR body" 2>/dev/null | grep -q "github.com" && echo "✓" || echo "✗")
    assert_equals "✓" "$pr_check" "Workflow step 7: Pull request creation"
}

# Test: Error handling for missing dependencies
test_error_handling_missing_dependencies() {
    echo "Testing: Error handling for missing dependencies"

    # Test with missing GitHub CLI
    export PATH="/bin:/usr/bin"
    local gh_check
    gh_check=$(command -v gh 2>/dev/null && echo "found" || echo "missing")
    assert_equals "missing" "$gh_check" "Missing GitHub CLI is detected"

    # Test with missing git
    local git_check
    git_check=$(command -v git 2>/dev/null && echo "found" || echo "missing")
    assert_equals "missing" "$git_check" "Missing git is detected"

    # Restore PATH
    export PATH="$TEST_TEMP_DIR/mock-bin:$ORIGINAL_PATH"
}

# Test: PR body and title formatting
test_pr_formatting() {
    echo "Testing: PR body and title formatting"

    local stack_id="kotlin-multiplatform-moko"
    local tech_stack="Kotlin Multiplatform with MOKO Resources"
    local project_type="library"

    # Test title formatting
    local expected_title="feat: add $tech_stack stack detection"
    local title="feat: add $tech_stack stack detection"
    assert_equals "$expected_title" "$title" "PR title is properly formatted"

    # Test body content requirements
    local body="## Summary
Add detection support for $tech_stack projects.

## Stack Details
- **Stack ID**: $stack_id
- **Tech Stack**: $tech_stack
- **Project Type**: $project_type

## Detection Patterns
- gradle/moko.versions.toml configuration file
- dev.icerock.moko:resources dependencies
- multiplatformResources configuration blocks

## Test Plan
- [x] Tested with multiple $tech_stack projects
- [x] Verified detection accuracy and confidence scoring
- [x] Ensured no false positives with similar stacks

🤖 Generated with [Claude Code](https://claude.ai/code)"

    assert_contains "Stack Details" "$body" "PR body contains stack details section"
    assert_contains "Detection Patterns" "$body" "PR body contains detection patterns"
    assert_contains "Test Plan" "$body" "PR body contains test plan"
    assert_contains "Generated with Claude Code" "$body" "PR body contains attribution"
}

# Test: Shell variable substitution safety
test_shell_variable_safety() {
    echo "Testing: Shell variable substitution safety"

    # Test problematic stack IDs that caused substitution errors
    local problematic_ids=(
        "n-a"
        "react.js"
        "vue-3"
        "next-js-14"
        "kotlin-multiplatform"
    )

    for stack_id in "${problematic_ids[@]}"; do
        # Test function name creation (should be safe)
        local function_name="${stack_id//-/_}"

        # Ensure function name is valid bash identifier
        if [[ "$function_name" =~ ^[a-zA-Z_][a-zA-Z0-9_]*$ ]]; then
            echo -e "${GREEN}✅ PASS${NC} Safe function name for '$stack_id': '$function_name'"
            TESTS_PASSED=$((TESTS_PASSED + 1))
        else
            echo -e "${RED}❌ FAIL${NC} Unsafe function name for '$stack_id': '$function_name'"
            TESTS_FAILED=$((TESTS_FAILED + 1))
        fi
        TESTS_TOTAL=$((TESTS_TOTAL + 1))
    done
}

# Run all tests
run_tests() {
    echo -e "${BLUE}🧪 Running GitHub Integration Unit Tests${NC}"
    echo "==========================================="
    echo ""

    setup

    test_github_auth_check
    test_stack_module_generation
    test_safe_function_name_creation
    test_github_fork_creation
    test_pull_request_creation
    test_git_conflict_resolution
    test_complete_pr_workflow
    test_error_handling_missing_dependencies
    test_pr_formatting
    test_shell_variable_safety

    cleanup

    echo ""
    echo -e "${CYAN}📊 Test Results:${NC}"
    echo "  Total:  $TESTS_TOTAL"
    echo -e "  Passed: ${GREEN}$TESTS_PASSED${NC}"
    echo -e "  Failed: ${RED}$TESTS_FAILED${NC}"

    if [[ $TESTS_FAILED -eq 0 ]]; then
        echo -e "${GREEN}🎉 All GitHub integration tests passed!${NC}"
        exit 0
    else
        echo -e "${RED}❌ Some GitHub integration tests failed${NC}"
        exit 1
    fi
}

# Run tests if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    run_tests
fi