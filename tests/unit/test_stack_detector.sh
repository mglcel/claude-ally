#!/bin/bash
# Unit tests for stack detector module

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

# Setup test environment
setup() {
    # Source the stack detector
    source "$ROOT_DIR/stack-detector.sh"

    # Create test fixtures
    mkdir -p /tmp/claude-ally-test-fixtures
}

# Cleanup test environment
cleanup() {
    rm -rf /tmp/claude-ally-test-fixtures
}

# Test: Load stack modules
test_load_stack_modules() {
    echo "Testing: load_stack_modules function"

    # Test that function exists
    assert_success "declare -f load_stack_modules" "load_stack_modules function exists"

    # Test that it can be called
    assert_success "load_stack_modules" "load_stack_modules executes without error"
}

# Test: Next.js AI detection
test_nextjs_ai_detection() {
    echo "Testing: Next.js AI detection"

    # Create test project structure
    local test_dir="/tmp/claude-ally-test-fixtures/nextjs-ai"
    mkdir -p "$test_dir"

    # Create package.json with Next.js and AI dependencies
    cat > "$test_dir/package.json" << 'EOF'
{
  "name": "test-nextjs-ai",
  "dependencies": {
    "next": "14.0.0",
    "@ai-sdk/openai": "^0.0.40",
    "ai": "^3.2.0",
    "react": "^18"
  },
  "devDependencies": {
    "typescript": "^5.0.0"
  }
}
EOF

    # Create next.config.js
    echo "module.exports = {}" > "$test_dir/next.config.js"

    # Create tsconfig.json
    echo "{}" > "$test_dir/tsconfig.json"

    # Test detection
    local result
    if result=$(detect_project_stack "$test_dir" 2>/dev/null); then
        assert_contains "nextjs-ai" "$result" "Next.js AI detection identifies correct stack"
        assert_contains "Next.js" "$result" "Next.js AI detection includes framework"
        assert_contains "AI/LLM" "$result" "Next.js AI detection includes AI/LLM"
        assert_contains "TypeScript" "$result" "Next.js AI detection includes TypeScript"
    else
        echo -e "${RED}❌ FAIL${NC} Next.js AI detection failed to detect project"
        TESTS_FAILED=$((TESTS_FAILED + 1))
        TESTS_TOTAL=$((TESTS_TOTAL + 1))
    fi
}

# Test: Python AI/ML detection
test_python_ai_detection() {
    echo "Testing: Python AI/ML detection"

    # Create test project structure
    local test_dir="/tmp/claude-ally-test-fixtures/python-ai"
    mkdir -p "$test_dir"

    # Create requirements.txt with AI/ML dependencies
    cat > "$test_dir/requirements.txt" << 'EOF'
torch==2.0.0
transformers==4.27.4
gradio==3.0.0
numpy==1.24.0
pandas==2.0.0
EOF

    # Create AI/ML project structure
    mkdir -p "$test_dir/models"
    echo "# AI model" > "$test_dir/models/model.py"
    echo "# Training script" > "$test_dir/train.py"

    # Test detection
    local result
    if result=$(detect_project_stack "$test_dir" 2>/dev/null); then
        assert_contains "python-ai" "$result" "Python AI detection identifies correct stack"
        assert_contains "Python" "$result" "Python AI detection includes Python"
        assert_contains "AI/ML" "$result" "Python AI detection includes AI/ML"
    else
        echo -e "${RED}❌ FAIL${NC} Python AI detection failed to detect project"
        TESTS_FAILED=$((TESTS_FAILED + 1))
        TESTS_TOTAL=$((TESTS_TOTAL + 1))
    fi
}

# Test: Cordova detection
test_cordova_detection() {
    echo "Testing: Cordova detection"

    # Create test project structure
    local test_dir="/tmp/claude-ally-test-fixtures/cordova"
    mkdir -p "$test_dir/www"

    # Create config.xml
    cat > "$test_dir/config.xml" << 'EOF'
<?xml version='1.0' encoding='utf-8'?>
<widget id="com.example.app" version="1.0.0">
    <name>TestApp</name>
    <platform name="android" />
    <platform name="ios" />
</widget>
EOF

    # Create package.json with Cordova dependencies
    cat > "$test_dir/package.json" << 'EOF'
{
  "name": "test-cordova",
  "dependencies": {
    "cordova-android": "6.3.0",
    "cordova-ios": "4.5.4",
    "mapbox-gl": "0.53.1"
  }
}
EOF

    # Test detection
    local result
    if result=$(detect_project_stack "$test_dir" 2>/dev/null); then
        assert_contains "cordova" "$result" "Cordova detection identifies correct stack"
        assert_contains "Cordova" "$result" "Cordova detection includes framework"
        assert_contains "Maps" "$result" "Cordova detection includes Maps integration"
    else
        echo -e "${RED}❌ FAIL${NC} Cordova detection failed to detect project"
        TESTS_FAILED=$((TESTS_FAILED + 1))
        TESTS_TOTAL=$((TESTS_TOTAL + 1))
    fi
}

# Test: Unknown stack detection
test_unknown_stack_detection() {
    echo "Testing: Unknown stack detection"

    # Create test project with unknown stack
    local test_dir="/tmp/claude-ally-test-fixtures/unknown"
    mkdir -p "$test_dir"

    # Create unrecognized files
    echo "some content" > "$test_dir/unknown.config"
    echo "unknown framework" > "$test_dir/main.unknown"

    # Test that detection returns failure (not detected)
    local result
    if result=$(detect_project_stack "$test_dir" 2>/dev/null); then
        echo -e "${RED}❌ FAIL${NC} Unknown stack should not be detected"
        TESTS_FAILED=$((TESTS_FAILED + 1))
        TESTS_TOTAL=$((TESTS_TOTAL + 1))
    else
        echo -e "${GREEN}✅ PASS${NC} Unknown stack correctly not detected"
        TESTS_PASSED=$((TESTS_PASSED + 1))
        TESTS_TOTAL=$((TESTS_TOTAL + 1))
    fi
}

# Test: Confidence scoring
test_confidence_scoring() {
    echo "Testing: Confidence scoring"

    # Create minimal Next.js project (should have lower confidence)
    local test_dir="/tmp/claude-ally-test-fixtures/minimal-nextjs"
    mkdir -p "$test_dir"

    cat > "$test_dir/package.json" << 'EOF'
{
  "name": "minimal-test",
  "dependencies": {
    "next": "14.0.0"
  }
}
EOF

    # Test that confidence is reasonable
    local result
    if result=$(detect_project_stack "$test_dir" 2>/dev/null); then
        local confidence
        confidence=$(echo "$result" | cut -d'|' -f4)

        if [[ $confidence -ge 50 ]] && [[ $confidence -le 100 ]]; then
            echo -e "${GREEN}✅ PASS${NC} Confidence scoring in valid range (50-100): $confidence"
            TESTS_PASSED=$((TESTS_PASSED + 1))
        else
            echo -e "${RED}❌ FAIL${NC} Confidence scoring out of range: $confidence"
            TESTS_FAILED=$((TESTS_FAILED + 1))
        fi
        TESTS_TOTAL=$((TESTS_TOTAL + 1))
    fi
}

# Run all tests
run_tests() {
    echo "🧪 Running Stack Detector Unit Tests"
    echo "=================================="

    setup

    test_load_stack_modules
    test_nextjs_ai_detection
    test_python_ai_detection
    test_cordova_detection
    test_unknown_stack_detection
    test_confidence_scoring

    cleanup

    echo ""
    echo "📊 Test Results:"
    echo "  Total:  $TESTS_TOTAL"
    echo -e "  Passed: ${GREEN}$TESTS_PASSED${NC}"
    echo -e "  Failed: ${RED}$TESTS_FAILED${NC}"

    if [[ $TESTS_FAILED -eq 0 ]]; then
        echo -e "${GREEN}🎉 All tests passed!${NC}"
        exit 0
    else
        echo -e "${RED}❌ Some tests failed${NC}"
        exit 1
    fi
}

# Run tests if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    run_tests
fi