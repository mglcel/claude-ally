#!/bin/bash
# Unit Tests for PHP Laravel Stack Detection
# Tests the new PHP Laravel stack detector

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
    TEST_TEMP_DIR=$(mktemp -d -t claude-ally-php-test-XXXXXX)
    echo -e "${BLUE}🧪 Running PHP Laravel Stack Detection Unit Tests${NC}"
    echo "=================================================="
    echo ""
}

cleanup() {
    rm -rf "$TEST_TEMP_DIR" 2>/dev/null || true
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

# Source the PHP Laravel stack detector
source_php_laravel_detector() {
    if [[ -f "$ROOT_DIR/stacks/php-laravel.sh" ]]; then
        source "$ROOT_DIR/stacks/php-laravel.sh"
        return 0
    else
        echo "PHP Laravel detector not found"
        return 1
    fi
}

# Test: Basic Laravel detection with composer.json
test_basic_laravel_detection() {
    echo "Testing: Basic Laravel detection with composer.json"

    # Create test project with Laravel composer.json
    mkdir -p "$TEST_TEMP_DIR/laravel_test"
    cat > "$TEST_TEMP_DIR/laravel_test/composer.json" << 'EOF'
{
    "name": "laravel/laravel",
    "require": {
        "php": "^8.2",
        "laravel/framework": "^10.0",
        "guzzlehttp/guzzle": "^7.2"
    }
}
EOF

    # Source the detector and test
    if source_php_laravel_detector; then
        local result
        result=$(detect_php_laravel "$TEST_TEMP_DIR/laravel_test")

        if [[ -n "$result" ]]; then
            # Parse the result
            IFS='|' read -r stack_id tech_stack project_type confidence <<< "$result"

            if [[ "$stack_id" == "php-laravel" ]]; then
                assert_success "Laravel detection identifies correct stack ID"
            else
                assert_failure "Laravel detection identifies correct stack ID" "Expected: php-laravel, got: $stack_id"
            fi

            if [[ "$tech_stack" == *"Laravel"* ]]; then
                assert_success "Laravel detection identifies correct tech stack"
            else
                assert_failure "Laravel detection identifies correct tech stack" "Expected Laravel in tech stack, got: $tech_stack"
            fi

            if [[ "$confidence" -ge 40 ]]; then
                assert_success "Laravel detection has sufficient confidence"
            else
                assert_failure "Laravel detection has sufficient confidence" "Expected confidence >= 40, got: $confidence"
            fi
        else
            assert_failure "Laravel detection returns result" "No result returned"
        fi
    else
        assert_failure "Source PHP Laravel detector" "Failed to source detector"
    fi
}

# Test: Laravel detection with artisan file
test_artisan_file_detection() {
    echo "Testing: Laravel detection with artisan file"

    # Create test project with artisan file
    mkdir -p "$TEST_TEMP_DIR/artisan_test"
    cat > "$TEST_TEMP_DIR/artisan_test/composer.json" << 'EOF'
{
    "name": "test/laravel-app",
    "require": {
        "php": "^8.2"
    }
}
EOF
    echo "#!/usr/bin/env php" > "$TEST_TEMP_DIR/artisan_test/artisan"

    # Source the detector and test
    if source_php_laravel_detector; then
        local result
        result=$(detect_php_laravel "$TEST_TEMP_DIR/artisan_test")

        if [[ -n "$result" ]]; then
            IFS='|' read -r stack_id tech_stack project_type confidence <<< "$result"

            if [[ "$stack_id" == "php-laravel" && "$tech_stack" == *"Laravel"* ]]; then
                assert_success "Artisan file triggers Laravel detection"
            else
                assert_failure "Artisan file triggers Laravel detection" "Stack: $stack_id, Tech: $tech_stack"
            fi
        else
            assert_failure "Artisan file detection returns result" "No result returned"
        fi
    else
        assert_failure "Source PHP Laravel detector" "Failed to source detector"
    fi
}

# Test: Laravel directory structure detection
test_laravel_directory_structure() {
    echo "Testing: Laravel directory structure detection"

    # Create test project with Laravel directory structure
    mkdir -p "$TEST_TEMP_DIR/structure_test"/{app,config,resources}
    cat > "$TEST_TEMP_DIR/structure_test/composer.json" << 'EOF'
{
    "name": "test/laravel-structure",
    "require": {
        "php": "^8.1"
    }
}
EOF

    # Source the detector and test
    if source_php_laravel_detector; then
        local result
        result=$(detect_php_laravel "$TEST_TEMP_DIR/structure_test")

        if [[ -n "$result" ]]; then
            IFS='|' read -r stack_id tech_stack project_type confidence <<< "$result"

            if [[ "$confidence" -gt 20 ]]; then
                assert_success "Laravel directory structure increases confidence"
            else
                assert_failure "Laravel directory structure increases confidence" "Expected confidence > 20, got: $confidence"
            fi
        else
            assert_failure "Laravel directory structure detection" "No result returned"
        fi
    else
        assert_failure "Source PHP Laravel detector" "Failed to source detector"
    fi
}

# Test: Specific Laravel files detection
test_laravel_specific_files() {
    echo "Testing: Laravel specific files detection"

    # Create test project with Laravel-specific files
    mkdir -p "$TEST_TEMP_DIR/specific_test"/{app/Http,config}
    cat > "$TEST_TEMP_DIR/specific_test/composer.json" << 'EOF'
{
    "name": "test/laravel-specific"
}
EOF
    echo "<?php" > "$TEST_TEMP_DIR/specific_test/app/Http/Kernel.php"
    echo "<?php" > "$TEST_TEMP_DIR/specific_test/config/app.php"

    # Source the detector and test
    if source_php_laravel_detector; then
        local result
        result=$(detect_php_laravel "$TEST_TEMP_DIR/specific_test")

        if [[ -n "$result" ]]; then
            IFS='|' read -r stack_id tech_stack project_type confidence <<< "$result"

            if [[ "$stack_id" == "php-laravel" ]]; then
                assert_success "Laravel specific files trigger detection"
            else
                assert_failure "Laravel specific files trigger detection" "Expected php-laravel, got: $stack_id"
            fi
        else
            assert_failure "Laravel specific files detection" "No result returned"
        fi
    else
        assert_failure "Source PHP Laravel detector" "Failed to source detector"
    fi
}

# Test: Non-Laravel PHP project detection
test_non_laravel_php_detection() {
    echo "Testing: Non-Laravel PHP project detection"

    # Create test project that's PHP but not Laravel
    mkdir -p "$TEST_TEMP_DIR/plain_php_test"
    cat > "$TEST_TEMP_DIR/plain_php_test/composer.json" << 'EOF'
{
    "name": "test/plain-php",
    "require": {
        "php": "^8.0",
        "guzzlehttp/guzzle": "^7.0"
    }
}
EOF
    echo "<?php echo 'Hello World';" > "$TEST_TEMP_DIR/plain_php_test/index.php"

    # Source the detector and test
    if source_php_laravel_detector; then
        local result
        result=$(detect_php_laravel "$TEST_TEMP_DIR/plain_php_test")

        if [[ -n "$result" ]]; then
            IFS='|' read -r stack_id tech_stack project_type confidence <<< "$result"

            # Should detect as PHP but with lower confidence than Laravel
            if [[ "$confidence" -lt 40 ]]; then
                assert_success "Plain PHP project has lower confidence than Laravel"
            else
                assert_failure "Plain PHP project has lower confidence than Laravel" "Expected confidence < 40, got: $confidence"
            fi
        else
            # It's OK if plain PHP doesn't trigger detection
            assert_success "Plain PHP project doesn't trigger Laravel detection"
        fi
    else
        assert_failure "Source PHP Laravel detector" "Failed to source detector"
    fi
}

# Test: Database type detection
test_database_detection() {
    echo "Testing: Database type detection"

    # Create test project with .env file indicating database
    mkdir -p "$TEST_TEMP_DIR/db_test"
    cat > "$TEST_TEMP_DIR/db_test/composer.json" << 'EOF'
{
    "name": "test/laravel-db",
    "require": {
        "laravel/framework": "^10.0"
    }
}
EOF
    cat > "$TEST_TEMP_DIR/db_test/.env" << 'EOF'
DB_CONNECTION=mysql
DB_HOST=127.0.0.1
DB_PORT=3306
DB_DATABASE=laravel
EOF

    # Source the detector and test
    if source_php_laravel_detector; then
        local result
        result=$(detect_php_laravel "$TEST_TEMP_DIR/db_test")

        if [[ -n "$result" ]]; then
            IFS='|' read -r stack_id tech_stack project_type confidence <<< "$result"

            if [[ "$tech_stack" == *"MySQL"* ]]; then
                assert_success "Database type detection from .env file"
            else
                assert_failure "Database type detection from .env file" "Expected MySQL in tech stack, got: $tech_stack"
            fi
        else
            assert_failure "Database detection returns result" "No result returned"
        fi
    else
        assert_failure "Source PHP Laravel detector" "Failed to source detector"
    fi
}

# Test: Stack patterns and assets
test_stack_patterns_and_assets() {
    echo "Testing: Stack patterns and assets retrieval"

    if source_php_laravel_detector; then
        # Test patterns
        local patterns
        patterns=$(get_php_laravel_patterns)

        if [[ "$patterns" == *"SQL Injection Prevention"* ]]; then
            assert_success "PHP Laravel patterns include security guidance"
        else
            assert_failure "PHP Laravel patterns include security guidance" "Security patterns not found"
        fi

        if [[ "$patterns" == *"CSRF Protection"* ]]; then
            assert_success "PHP Laravel patterns include CSRF protection"
        else
            assert_failure "PHP Laravel patterns include CSRF protection" "CSRF patterns not found"
        fi

        # Test assets
        local assets
        assets=$(get_php_laravel_assets)

        if [[ "$assets" == *"database credentials"* ]]; then
            assert_success "PHP Laravel assets include database credentials"
        else
            assert_failure "PHP Laravel assets include database credentials" "Database credentials not in assets"
        fi

        if [[ "$assets" == *"session data"* ]]; then
            assert_success "PHP Laravel assets include session data"
        else
            assert_failure "PHP Laravel assets include session data" "Session data not in assets"
        fi

        # Test issues
        local issues
        issues=$(get_php_laravel_issues)

        if [[ "$issues" == *"migration problems"* ]]; then
            assert_success "PHP Laravel issues include migration problems"
        else
            assert_failure "PHP Laravel issues include migration problems" "Migration problems not in issues"
        fi
    else
        assert_failure "Source PHP Laravel detector for patterns test" "Failed to source detector"
    fi
}

# Test: Confidence scoring
test_confidence_scoring() {
    echo "Testing: Confidence scoring accuracy"

    # Test different scenarios and their confidence levels
    local test_scenarios=(
        "laravel_framework_only"
        "artisan_plus_structure"
        "full_laravel_project"
    )

    for scenario in "${test_scenarios[@]}"; do
        local test_dir="$TEST_TEMP_DIR/$scenario"
        mkdir -p "$test_dir"

        case "$scenario" in
            "laravel_framework_only")
                cat > "$test_dir/composer.json" << 'EOF'
{
    "require": {
        "laravel/framework": "^10.0"
    }
}
EOF
                ;;
            "artisan_plus_structure")
                cat > "$test_dir/composer.json" << 'EOF'
{
    "require": {
        "laravel/framework": "^10.0"
    }
}
EOF
                echo "#!/usr/bin/env php" > "$test_dir/artisan"
                mkdir -p "$test_dir"/{app,config,resources}
                ;;
            "full_laravel_project")
                cat > "$test_dir/composer.json" << 'EOF'
{
    "require": {
        "laravel/framework": "^10.0"
    }
}
EOF
                echo "#!/usr/bin/env php" > "$test_dir/artisan"
                mkdir -p "$test_dir"/{app/Http,config}
                echo "<?php" > "$test_dir/app/Http/Kernel.php"
                echo "<?php" > "$test_dir/config/app.php"
                cat > "$test_dir/.env" << 'EOF'
DB_CONNECTION=mysql
EOF
                ;;
        esac

        if source_php_laravel_detector; then
            local result
            result=$(detect_php_laravel "$test_dir")

            if [[ -n "$result" ]]; then
                IFS='|' read -r stack_id tech_stack project_type confidence <<< "$result"

                case "$scenario" in
                    "laravel_framework_only")
                        if [[ "$confidence" -ge 40 ]]; then
                            assert_success "Laravel framework only has sufficient confidence ($confidence)"
                        else
                            assert_failure "Laravel framework only has sufficient confidence" "Expected >= 40, got: $confidence"
                        fi
                        ;;
                    "artisan_plus_structure")
                        if [[ "$confidence" -ge 60 ]]; then
                            assert_success "Artisan plus structure has high confidence ($confidence)"
                        else
                            assert_failure "Artisan plus structure has high confidence" "Expected >= 60, got: $confidence"
                        fi
                        ;;
                    "full_laravel_project")
                        if [[ "$confidence" -ge 80 ]]; then
                            assert_success "Full Laravel project has very high confidence ($confidence)"
                        else
                            assert_failure "Full Laravel project has very high confidence" "Expected >= 80, got: $confidence"
                        fi
                        ;;
                esac
            else
                assert_failure "Confidence scoring for $scenario" "No result returned"
            fi
        else
            assert_failure "Source detector for confidence test" "Failed to source detector"
        fi
    done
}

teardown() {
    cleanup

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

# Run the test suite
main() {
    setup

    test_basic_laravel_detection
    test_artisan_file_detection
    test_laravel_directory_structure
    test_laravel_specific_files
    test_non_laravel_php_detection
    test_database_detection
    test_stack_patterns_and_assets
    test_confidence_scoring

    teardown
}

# Run if called directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi