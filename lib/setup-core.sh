#!/bin/bash
#
# Claude-Ally Setup Core Module
# Core orchestration and directory detection functionality
#

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Global variables (initialized if not already set)
SCRIPT_DIR="${SCRIPT_DIR:-}"
PROJECT_DIR="${PROJECT_DIR:-}"
WORKING_DIR="${WORKING_DIR:-}"
NON_INTERACTIVE="${NON_INTERACTIVE:-false}"

# Detect if we're in non-interactive mode
detect_non_interactive() {
    if [[ ! -t 0 ]]; then
        NON_INTERACTIVE=true
        echo "🤖 Non-interactive mode detected - using automatic defaults"
    fi
}

# Detect script and project directories
detect_directories() {
    # Get the directory where this script is located
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

    # Get the current working directory (project directory)
    WORKING_DIR="$(pwd)"
    PROJECT_DIR="$WORKING_DIR"

    echo -e "${BLUE}📁 Directory Detection${NC}"
    echo "------------------------------"
    echo "Claude Ally script: $SCRIPT_DIR"
    echo "Project directory: $PROJECT_DIR"
    echo ""

    # Check if we're in the claude-ally directory itself
    if [[ "$SCRIPT_DIR" == "$PROJECT_DIR" ]]; then
        echo -e "${YELLOW}⚠️  You're running this script from the claude-ally directory itself.${NC}"
        echo "This will analyze the claude-ally project instead of your project."
        echo ""
        # Check if we're in interactive mode
        if [[ "$NON_INTERACTIVE" == "true" ]]; then
            # Non-interactive mode - default to yes
            ANALYZE_SELF="Y"
            echo "Non-interactive mode: continuing with claude-ally analysis..."
        else
            read -r -p "Do you want to continue analyzing claude-ally? (Y/n): " ANALYZE_SELF
        fi

        if [[ "$ANALYZE_SELF" =~ ^[Nn]$ ]]; then
            echo -e "${CYAN}💡 TIP: Run this script from your project directory:${NC}"
            echo "   cd /path/to/your/project"
            echo "   $SCRIPT_DIR/setup.sh"
            exit 0
        fi
    fi
}

# Print main header
print_header() {
    echo "============================================================"
    echo "🤖 CLAUDE ALLY - COGNITIVE ENHANCEMENT SETUP"
    echo "🧠 Enhanced with Claude Intelligence"
    echo "============================================================"
    echo "This script will analyze your repository and use Claude to suggest"
    echo "intelligent defaults for your cognitive enhancement system."
    echo ""
}

# Validate inputs
validate_inputs() {
    local project_name="$1"
    local project_type="$2"
    local tech_stack="$3"
    local critical_assets="$4"
    local common_issues="$5"

    if [[ -z "$project_name" ]] || [[ -z "$project_type" ]] || [[ -z "$tech_stack" ]]; then
        echo -e "${RED}❌ Error: Missing required information${NC}"
        echo "Project name, type, and tech stack are required."
        return 1
    fi

    return 0
}

# Cleanup function
cleanup() {
    # Clean up any temporary files
    if [[ -n "${CLAUDE_SUGGESTIONS_FILE:-}" ]] && [[ -f "$CLAUDE_SUGGESTIONS_FILE" ]]; then
        rm -f "$CLAUDE_SUGGESTIONS_FILE" 2>/dev/null || true
    fi
}

# Set up cleanup trap
trap cleanup EXIT INT TERM