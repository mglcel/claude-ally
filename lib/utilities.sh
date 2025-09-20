#!/bin/bash
#
# Claude-Ally Utilities Module
# Consolidated utility functions for error handling, caching, and progress indication
#

# Colors for output formatting
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Error handling
handle_error() {
    local error_message="$1"
    local exit_code="${2:-1}"

    echo -e "${RED}❌ Error: $error_message${NC}" >&2

    if [[ "$exit_code" != "0" ]]; then
        exit "$exit_code"
    fi
}

# Simple cache implementation (used by contribute-stack.sh)
create_cache_key() {
    local project_dir="$1"
    local project_name="$2"
    echo "${project_dir}_${project_name}" | md5sum 2>/dev/null | cut -d' ' -f1 || echo "${project_dir}_${project_name}" | shasum -a 256 | cut -d' ' -f1
}

# Check if cache file is valid (less than 60 minutes old)
is_cache_valid() {
    local cache_file="$1"
    [[ -f "$cache_file" ]] && [[ $(find "$cache_file" -mmin -60 2>/dev/null) ]]
}

# Progress indication for long operations
show_spinner() {
    local message="$1"
    local pid="$2"

    local spin='⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏'
    local i=0

    echo -n "$message "
    while kill -0 "$pid" 2>/dev/null; do
        printf "\r%s %c" "$message" "${spin:$i%${#spin}:1}"
        ((i++))
        sleep 0.1
    done
    printf "\r%s ✅\n" "$message"
}

# Basic configuration validation
validate_basic_config() {
    local config_file="$1"

    if [[ ! -f "$config_file" ]]; then
        return 1
    fi

    # Basic JSON validation if jq is available
    if command -v jq >/dev/null 2>&1; then
        jq empty "$config_file" >/dev/null 2>&1
    else
        # Simple bracket matching for basic validation
        [[ $(grep -c '{' "$config_file") -eq $(grep -c '}' "$config_file") ]]
    fi
}

# File size formatting
format_file_size() {
    local size="$1"

    if [[ $size -gt 1048576 ]]; then
        echo "$((size / 1048576))MB"
    elif [[ $size -gt 1024 ]]; then
        echo "$((size / 1024))KB"
    else
        echo "${size}B"
    fi
}

# Check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Safe cleanup function
cleanup_temp_files() {
    local pattern="$1"
    find /tmp -name "$pattern" -mtime +1 -delete 2>/dev/null || true
}