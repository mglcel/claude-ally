#!/bin/bash
# Enhanced Error Handling & Recovery System
# Provides robust error handling with automatic recovery options

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

# Error codes
declare -A ERROR_CODES=(
    [1]="General error"
    [2]="Misuse of shell builtins"
    [126]="Command invoked cannot execute"
    [127]="Command not found"
    [128]="Invalid argument to exit"
    [130]="Script terminated by Control-C"
)

# Error log file
ERROR_LOG="$HOME/.claude-ally/error.log"

# Initialize error logging
init_error_logging() {
    mkdir -p "$(dirname "$ERROR_LOG")"
    touch "$ERROR_LOG"
}

# Log error with context
log_error() {
    local error_code="$1"
    local error_message="$2"
    local function_name="${3:-unknown}"
    local line_number="${4:-unknown}"

    init_error_logging

    local timestamp
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')

    local error_entry="[$timestamp] ERROR $error_code in $function_name:$line_number - $error_message"
    echo "$error_entry" >> "$ERROR_LOG"

    # Show user-friendly error
    echo -e "${RED}❌ Error occurred: $error_message${NC}"
    echo -e "${YELLOW}💡 Error details logged to: $ERROR_LOG${NC}"
}

# Enhanced error handler with recovery suggestions
handle_error() {
    local exit_code="$1"
    local error_context="$2"

    case "$exit_code" in
        127)
            echo -e "${RED}❌ Command not found${NC}"
            suggest_command_installation "$error_context"
            ;;
        126)
            echo -e "${RED}❌ Permission denied${NC}"
            suggest_permission_fix "$error_context"
            ;;
        130)
            echo -e "${YELLOW}⚠️ Script interrupted by user${NC}"
            offer_resume_option
            ;;
        *)
            local error_desc="${ERROR_CODES[$exit_code]:-Unknown error}"
            echo -e "${RED}❌ $error_desc (code: $exit_code)${NC}"
            suggest_general_recovery "$error_context"
            ;;
    esac
}

# Suggest command installation
suggest_command_installation() {
    local missing_command="$1"

    echo -e "${CYAN}🔧 Suggested fixes:${NC}"

    case "$missing_command" in
        "gh")
            echo "  Install GitHub CLI:"
            echo "    macOS: brew install gh"
            echo "    Ubuntu: sudo apt install gh"
            echo "    Windows: choco install gh"
            ;;
        "git")
            echo "  Install Git:"
            echo "    macOS: brew install git"
            echo "    Ubuntu: sudo apt install git"
            echo "    Windows: Download from git-scm.com"
            ;;
        "claude")
            echo "  Install Claude CLI:"
            echo "    Visit: https://claude.ai/code"
            echo "    Follow installation instructions"
            ;;
        *)
            echo "  Check if $missing_command is installed"
            echo "  Add to PATH if already installed"
            ;;
    esac
}

# Suggest permission fixes
suggest_permission_fix() {
    local file_context="$1"

    echo -e "${CYAN}🔧 Permission fixes:${NC}"
    echo "  Make file executable: chmod +x $file_context"
    echo "  Check file ownership: ls -la $file_context"
    echo "  Fix ownership: sudo chown \$USER $file_context"
}

# Offer resume option after interruption
offer_resume_option() {
    echo -e "${CYAN}🔄 Resume options:${NC}"
    echo "  Run the script again to continue"
    echo "  Use --resume flag if available"
    echo "  Check for partially completed files"
}

# General recovery suggestions
suggest_general_recovery() {
    local context="$1"

    echo -e "${CYAN}🔧 General recovery steps:${NC}"
    echo "  1. Check error log: $ERROR_LOG"
    echo "  2. Verify all dependencies are installed"
    echo "  3. Check file permissions and paths"
    echo "  4. Try running with verbose mode: bash -x script.sh"
    echo "  5. Report issue at: https://github.com/mglcel/claude-ally/issues"

    # Offer to open error log
    local open_log_choice
    read -p "Would you like to view the error log? (y/N): " open_log_choice

    if [[ "$open_log_choice" =~ ^[Yy] ]]; then
        if command -v less &> /dev/null; then
            less "$ERROR_LOG"
        else
            cat "$ERROR_LOG"
        fi
    fi
}

# Validation functions
validate_dependencies() {
    local required_commands=("git" "bash" "grep" "sed" "find")
    local missing_commands=()

    for cmd in "${required_commands[@]}"; do
        if ! command -v "$cmd" &> /dev/null; then
            missing_commands+=("$cmd")
        fi
    done

    if [[ ${#missing_commands[@]} -gt 0 ]]; then
        echo -e "${RED}❌ Missing required dependencies:${NC}"
        printf '  %s\n' "${missing_commands[@]}"
        return 1
    fi

    echo -e "${GREEN}✅ All required dependencies available${NC}"
    return 0
}

validate_permissions() {
    local file_path="$1"

    if [[ ! -r "$file_path" ]]; then
        echo -e "${RED}❌ Cannot read file: $file_path${NC}"
        suggest_permission_fix "$file_path"
        return 1
    fi

    if [[ -f "$file_path" ]] && [[ ! -x "$file_path" ]]; then
        echo -e "${YELLOW}⚠️ File not executable: $file_path${NC}"
        echo -e "${CYAN}💡 Fix with: chmod +x $file_path${NC}"
        return 1
    fi

    return 0
}

# Recovery mode
recovery_mode() {
    echo -e "${PURPLE}🛠️ CLAUDE-ALLY RECOVERY MODE${NC}"
    echo -e "${BOLD}==============================${NC}"
    echo ""

    echo -e "${CYAN}Running system diagnostics...${NC}"

    # Check dependencies
    echo "1. Checking dependencies..."
    validate_dependencies

    # Check key files
    echo "2. Checking key files..."
    local key_files=("setup.sh" "stack-detector.sh" "contribute-stack.sh")

    for file in "${key_files[@]}"; do
        if [[ -f "/private/tmp/claude-ally/$file" ]]; then
            validate_permissions "/private/tmp/claude-ally/$file"
        else
            echo -e "${RED}❌ Missing file: $file${NC}"
        fi
    done

    # Check cache
    echo "3. Checking cache..."
    if [[ -f "/private/tmp/claude-ally/cache-manager.sh" ]]; then
        source "/private/tmp/claude-ally/cache-manager.sh"
        cache_stats
    fi

    # Show recent errors
    echo "4. Recent errors:"
    if [[ -f "$ERROR_LOG" ]]; then
        tail -5 "$ERROR_LOG"
    else
        echo "  No errors logged"
    fi

    echo ""
    echo -e "${GREEN}Recovery mode completed${NC}"
}

# Set up error trapping
setup_error_trapping() {
    set -eE  # Exit on error, inherit ERR trap
    trap 'handle_error $? "$BASH_COMMAND"' ERR
    trap 'log_error 130 "Script interrupted" "${FUNCNAME[1]}" "${LINENO}"' INT
}

# Clean up error trapping
cleanup_error_trapping() {
    set +eE
    trap - ERR INT
}