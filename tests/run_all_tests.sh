#!/bin/bash
# Claude-Ally Comprehensive Test Runner
# Orchestrates all test suites: unit, integration, and end-to-end tests

set -euo pipefail

# Get script directory and project root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

# Test results
TOTAL_SUITES=0
PASSED_SUITES=0
FAILED_SUITES=0

# Configuration
PARALLEL_EXECUTION=${PARALLEL_TESTS:-false}
VERBOSE=${VERBOSE:-false}
STOP_ON_FAILURE=${STOP_ON_FAILURE:-false}

# Help function
show_help() {
    echo -e "${BOLD}Claude-Ally Test Runner${NC}"
    echo ""
    echo -e "${CYAN}USAGE:${NC}"
    echo "  $0 [options] [test-type]"
    echo ""
    echo -e "${CYAN}TEST TYPES:${NC}"
    echo "  unit         Run only unit tests"
    echo "  integration  Run only integration tests"
    echo "  e2e          Run only end-to-end tests"
    echo "  all          Run all test suites (default)"
    echo ""
    echo -e "${CYAN}OPTIONS:${NC}"
    echo "  -p, --parallel     Run tests in parallel where possible"
    echo "  -v, --verbose      Enable verbose output"
    echo "  -s, --stop         Stop on first test suite failure"
    echo "  -h, --help         Show this help message"
    echo ""
    echo -e "${CYAN}ENVIRONMENT VARIABLES:${NC}"
    echo "  PARALLEL_TESTS     Set to 'true' for parallel execution"
    echo "  VERBOSE           Set to 'true' for verbose output"
    echo "  STOP_ON_FAILURE   Set to 'true' to stop on first failure"
    echo ""
    echo -e "${CYAN}EXAMPLES:${NC}"
    echo "  $0                 # Run all tests"
    echo "  $0 unit            # Run only unit tests"
    echo "  $0 --parallel all  # Run all tests in parallel"
    echo "  $0 -v -s unit      # Run unit tests with verbose output, stop on failure"
    echo ""
}

# Logging functions
log_info() {
    echo -e "${BLUE}ℹ${NC} $*"
}

log_success() {
    echo -e "${GREEN}✅${NC} $*"
}

log_error() {
    echo -e "${RED}❌${NC} $*"
}

log_warning() {
    echo -e "${YELLOW}⚠️${NC} $*"
}

log_section() {
    echo ""
    echo -e "${PURPLE}═══════════════════════════════════════════════════════════════════════════════${NC}"
    echo -e "${BOLD}$*${NC}"
    echo -e "${PURPLE}═══════════════════════════════════════════════════════════════════════════════${NC}"
    echo ""
}

# Test execution functions
run_test_suite() {
    local suite_name="$1"
    local test_script="$2"
    local description="$3"

    TOTAL_SUITES=$((TOTAL_SUITES + 1))

    if [[ ! -f "$test_script" ]]; then
        log_error "$suite_name suite: Test script not found at $test_script"
        FAILED_SUITES=$((FAILED_SUITES + 1))
        return 1
    fi

    if [[ ! -x "$test_script" ]]; then
        log_error "$suite_name suite: Test script is not executable at $test_script"
        FAILED_SUITES=$((FAILED_SUITES + 1))
        return 1
    fi

    log_section "$suite_name Tests - $description"

    local start_time
    start_time=$(date +%s)

    if [[ "$VERBOSE" == "true" ]]; then
        log_info "Executing: $test_script"
        log_info "Working directory: $(pwd)"
        log_info "Start time: $(date)"
        echo ""
    fi

    # Execute the test suite
    local exit_code=0
    if [[ "$VERBOSE" == "true" ]]; then
        bash "$test_script" || exit_code=$?
    else
        bash "$test_script" 2>&1 | while IFS= read -r line; do
            # Filter output to show only important information
            if [[ "$line" =~ (✅|❌|⚠️|🎉|📊|Total:|Passed:|Failed:) ]]; then
                echo "$line"
            elif [[ "$line" =~ ^(Testing:|Running|Scenario:) ]]; then
                echo "$line"
            fi
        done || exit_code=$?
    fi

    local end_time
    end_time=$(date +%s)
    local duration=$((end_time - start_time))

    if [[ $exit_code -eq 0 ]]; then
        log_success "$suite_name suite completed successfully in ${duration}s"
        PASSED_SUITES=$((PASSED_SUITES + 1))
        return 0
    else
        log_error "$suite_name suite failed after ${duration}s (exit code: $exit_code)"
        FAILED_SUITES=$((FAILED_SUITES + 1))

        if [[ "$STOP_ON_FAILURE" == "true" ]]; then
            log_error "Stopping test execution due to failure (--stop option enabled)"
            exit 1
        fi

        return 1
    fi
}

# Pre-flight checks
pre_flight_checks() {
    log_section "Pre-Flight System Validation"

    local issues=0

    # Check if we're in the right directory
    if [[ ! -f "$ROOT_DIR/claude-ally.sh" ]]; then
        log_error "Main claude-ally.sh not found. Are you running from the correct directory?"
        ((issues++))
    else
        log_success "Main claude-ally.sh found"
    fi

    # Check test directory structure
    local test_dirs=("unit" "integration" "end-to-end")
    for dir in "${test_dirs[@]}"; do
        if [[ -d "$SCRIPT_DIR/$dir" ]]; then
            log_success "Test directory exists: $dir"
        else
            log_warning "Test directory missing: $dir"
            ((issues++))
        fi
    done

    # Check critical system dependencies
    local deps=("bash" "git" "grep" "find" "sed")
    for dep in "${deps[@]}"; do
        if command -v "$dep" &> /dev/null; then
            log_success "System dependency available: $dep"
        else
            log_error "Missing required dependency: $dep"
            ((issues++))
        fi
    done

    # Check optional dependencies
    local opt_deps=("gh" "jq")
    for dep in "${opt_deps[@]}"; do
        if command -v "$dep" &> /dev/null; then
            log_success "Optional dependency available: $dep"
        else
            log_info "Optional dependency not found: $dep (some features may be limited)"
        fi
    done

    echo ""
    if [[ $issues -eq 0 ]]; then
        log_success "Pre-flight checks passed successfully"
        return 0
    else
        log_error "$issues issues found during pre-flight checks"
        log_warning "Some tests may fail due to missing dependencies or incorrect setup"
        return 1
    fi
}

# Main test execution
run_unit_tests() {
    run_test_suite \
        "Unit - Stack Detector" \
        "$SCRIPT_DIR/unit/test_stack_detector.sh" \
        "Core stack detection functionality"

    run_test_suite \
        "Unit - Contribute Functionality" \
        "$SCRIPT_DIR/unit/test_contribute_functionality.sh" \
        "Contribute workflow with Claude mocking"

    run_test_suite \
        "Unit - GitHub Integration" \
        "$SCRIPT_DIR/unit/test_github_integration.sh" \
        "GitHub PR automation and integration"
}

run_integration_tests() {
    run_test_suite \
        "Integration - CLI Commands" \
        "$SCRIPT_DIR/integration/test_cli_integration.sh" \
        "Complete CLI workflow testing with mocking"
}

run_e2e_tests() {
    run_test_suite \
        "End-to-End" \
        "$SCRIPT_DIR/end-to-end/test_complete_workflows.sh" \
        "Complete user workflows and scenarios"
}

# Results summary
show_results_summary() {
    log_section "Test Execution Summary"

    echo -e "${CYAN}📊 Overall Results:${NC}"
    echo "  Total Suites: $TOTAL_SUITES"
    echo -e "  Passed:       ${GREEN}$PASSED_SUITES${NC}"
    echo -e "  Failed:       ${RED}$FAILED_SUITES${NC}"

    local success_rate=0
    if [[ $TOTAL_SUITES -gt 0 ]]; then
        success_rate=$((PASSED_SUITES * 100 / TOTAL_SUITES))
    fi

    echo -e "  Success Rate: ${CYAN}${success_rate}%${NC}"
    echo ""

    if [[ $FAILED_SUITES -eq 0 ]]; then
        log_success "All test suites passed successfully! 🎉"
        echo -e "${GREEN}🚀 Claude-ally is ready for production use${NC}"
        echo ""
        echo -e "${CYAN}Next Steps:${NC}"
        echo "  1. Commit your changes: git add . && git commit -m 'Add comprehensive test suite'"
        echo "  2. Set up GitHub Actions workflow for CI/CD"
        echo "  3. Add test badge to README.md"
        echo ""
        return 0
    else
        log_error "Some test suites failed"
        echo ""
        echo -e "${YELLOW}Troubleshooting:${NC}"
        echo "  1. Run individual test suites with --verbose for detailed output"
        echo "  2. Check system dependencies and setup"
        echo "  3. Review failed test outputs above"
        echo "  4. Run 'claude-ally validate' for system diagnostics"
        echo ""
        return 1
    fi
}

# Main execution logic
main() {
    local test_type="all"

    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -p|--parallel)
                PARALLEL_EXECUTION="true"
                shift
                ;;
            -v|--verbose)
                VERBOSE="true"
                shift
                ;;
            -s|--stop)
                STOP_ON_FAILURE="true"
                shift
                ;;
            -h|--help)
                show_help
                exit 0
                ;;
            unit|integration|e2e|all)
                test_type="$1"
                shift
                ;;
            *)
                log_error "Unknown option: $1"
                show_help
                exit 1
                ;;
        esac
    done

    # Show configuration
    echo -e "${BOLD}Claude-Ally Comprehensive Test Suite${NC}"
    echo -e "${CYAN}Version: 2.0.0${NC}"
    echo ""
    echo -e "${CYAN}Configuration:${NC}"
    echo "  Test Type:        $test_type"
    echo "  Parallel:         $PARALLEL_EXECUTION"
    echo "  Verbose:          $VERBOSE"
    echo "  Stop on Failure:  $STOP_ON_FAILURE"
    echo "  Working Dir:      $ROOT_DIR"
    echo ""

    # Run pre-flight checks
    if ! pre_flight_checks; then
        log_warning "Pre-flight checks had issues, but continuing with test execution"
    fi

    # Execute test suites based on type
    case "$test_type" in
        "unit")
            run_unit_tests
            ;;
        "integration")
            run_integration_tests
            ;;
        "e2e")
            run_e2e_tests
            ;;
        "all")
            if [[ "$PARALLEL_EXECUTION" == "true" ]]; then
                log_info "Parallel execution not yet implemented, running sequentially"
            fi

            run_unit_tests
            run_integration_tests
            run_e2e_tests
            ;;
        *)
            log_error "Invalid test type: $test_type"
            show_help
            exit 1
            ;;
    esac

    # Show final results
    show_results_summary
}

# Cleanup function
cleanup() {
    # Clean up any temporary files or processes
    if [[ -d "/tmp/claude-ally-test-"* ]]; then
        rm -rf /tmp/claude-ally-test-* 2>/dev/null || true
    fi
}

# Set up cleanup trap
trap cleanup EXIT INT TERM

# Run main function
main "$@"