#!/bin/bash
#
# Claude-Ally - Universal Claude Cognitive Enhancement System
# Main CLI interface for all claude-ally functionality
# Production-Ready Enterprise Tool
#

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

# Version
VERSION="1.0.0"

# Load essential modules only
load_modules() {
    local modules=(
        "lib/stack-detector.sh"
        "lib/contribute-stack.sh"
    )

    for module in "${modules[@]}"; do
        if [[ -f "$SCRIPT_DIR/$module" ]]; then
            source "$SCRIPT_DIR/$module" 2>/dev/null || echo "Warning: Failed to load $module"
        fi
    done
}

# Show version information
show_version() {
    echo -e "${BOLD}Claude-Ally Universal Cognitive Enhancement System${NC}"
    echo -e "${CYAN}Version: $VERSION${NC}"
    echo -e "${BLUE}Repository: https://github.com/mglcel/claude-ally${NC}"
    echo ""
    echo -e "${GREEN}Features:${NC}"
    echo "  ✅ Automatic project stack detection"
    echo "  ✅ Cognitive enhancement setup for Claude"
    echo "  ✅ Community contribution workflow"
    echo "  ✅ Cross-platform compatibility"
    echo ""
}

# Show help information
show_help() {
    echo -e "${BOLD}Claude-Ally - Universal Claude Cognitive Enhancement System${NC}"
    echo ""
    echo -e "${CYAN}USAGE:${NC}"
    echo "  /path/to/claude-ally/claude-ally.sh <command> [options]"
    echo ""
    echo -e "${YELLOW}NOTE:${NC} Run from your project directory for best results:"
    echo "  cd /path/to/your/project"
    echo "  /path/to/claude-ally/claude-ally.sh setup"
    echo ""
    echo -e "${CYAN}COMMANDS:${NC}"
    echo "  setup [directory]          Setup cognitive enhancement for a project"
    echo "  detect [directory]         Detect project technology stack (optional)"
    echo "  contribute [directory]     Contribute new stack to claude-ally"
    echo "  validate <file>            Validate a generated prompt file"
    echo "  version                    Show version information"
    echo "  help                       Show this help message"
    echo ""
    echo -e "${CYAN}EXAMPLES:${NC}"
    echo "  cd /path/to/your/project"
    echo "  /path/to/claude-ally/claude-ally.sh setup                    # Setup current directory"
    echo "  /path/to/claude-ally/claude-ally.sh setup /path/to/project   # Setup specific project"
    echo "  /path/to/claude-ally/claude-ally.sh detect                   # See what was detected"
    echo "  /path/to/claude-ally/claude-ally.sh contribute               # Contribute unknown stack"
    echo "  /path/to/claude-ally/claude-ally.sh validate prompt.txt     # Validate prompt quality"
    echo ""
    echo -e "${BLUE}For more information: https://github.com/mglcel/claude-ally${NC}"
}

# Validate system setup
validate_system() {
    # Start multi-step validation if available
    if declare -f start_multi_step > /dev/null; then
        start_multi_step 5 "System Validation"
    else
        echo -e "${CYAN}🔍 Validating claude-ally system...${NC}"
        echo ""
    fi

    local issues=0

    # Check core files
    if declare -f execute_step > /dev/null; then
        if execute_step "Checking core files" "sleep 0.5"; then
            echo "Core files validation:"
        fi
    else
        echo "1. Checking core files..."
    fi
    local core_files=("setup.sh" "lib/stack-detector.sh" "contribute-stack.sh")
    for file in "${core_files[@]}"; do
        if [[ -f "$SCRIPT_DIR/$file" ]]; then
            echo -e "  ✅ $file"
        else
            echo -e "  ❌ $file (missing)"
            ((issues++))
        fi
    done

    # Check optimization modules
    echo ""
    echo "2. Checking optimization modules..."
    local opt_modules=("lib/error-handler.sh" "lib/config-manager.sh" "lib/cache-manager.sh" "lib/performance-monitor.sh")
    for module in "${opt_modules[@]}"; do
        if [[ -f "$SCRIPT_DIR/$module" ]]; then
            echo -e "  ✅ $module"
        else
            echo -e "  ⚠️ $module (optional)"
        fi
    done

    # Check stack modules
    echo ""
    echo "3. Checking stack detection modules..."
    if [[ -d "$SCRIPT_DIR/stacks" ]]; then
        local stack_count
        stack_count=$(find "$SCRIPT_DIR/stacks" -name "*.sh" | wc -l)
        echo -e "  ✅ Stack modules directory ($stack_count modules)"

        for stack_file in "$SCRIPT_DIR/stacks"/*.sh; do
            if [[ -f "$stack_file" ]]; then
                local stack_name
                stack_name=$(basename "$stack_file" .sh)
                echo -e "    • $stack_name"
            fi
        done
    else
        echo -e "  ❌ Stack modules directory (missing)"
        ((issues++))
    fi

    # Check dependencies
    echo ""
    echo "4. Checking dependencies..."
    local required_deps=("git" "bash" "grep" "sed" "find")
    for dep in "${required_deps[@]}"; do
        if command -v "$dep" &> /dev/null; then
            echo -e "  ✅ $dep"
        else
            echo -e "  ❌ $dep (required)"
            ((issues++))
        fi
    done

    local optional_deps=("gh" "jq" "claude")
    for dep in "${optional_deps[@]}"; do
        if command -v "$dep" &> /dev/null; then
            echo -e "  ✅ $dep (optional)"
        else
            echo -e "  ⚠️ $dep (optional, but recommended)"
        fi
    done

    # Check configuration
    echo ""
    echo "5. Checking configuration..."
    if declare -f validate_config > /dev/null; then
        if validate_config &> /dev/null; then
            echo -e "  ✅ Configuration valid"
        else
            echo -e "  ⚠️ Configuration issues detected"
        fi
    else
        echo -e "  ⚠️ Configuration validation not available"
    fi

    # Finish multi-step operation if available
    if declare -f finish_multi_step > /dev/null; then
        if [[ $issues -eq 0 ]]; then
            finish_multi_step true
        else
            finish_multi_step false
        fi
    else
        echo ""
        if [[ $issues -eq 0 ]]; then
            echo -e "${GREEN}✅ System validation completed successfully!${NC}"
            echo -e "${CYAN}🚀 Claude-ally is ready for use${NC}"
        else
            echo -e "${YELLOW}⚠️ System validation completed with $issues issues${NC}"
            echo -e "${CYAN}💡 Run 'claude-ally recovery' to attempt automatic fixes${NC}"
        fi
    fi
}

# Main CLI dispatcher
main() {
    load_modules

    local command="${1:-help}"
    shift || true

    case "$command" in
        "setup")
            if [[ -f "$SCRIPT_DIR/lib/setup.sh" ]]; then
                # Don't use time_operation for setup since it's interactive and captures output
                bash "$SCRIPT_DIR/lib/setup.sh" "$@"
            else
                if declare -f show_error > /dev/null; then
                    show_error "Setup script not found"
                else
                    echo -e "${RED}❌ Setup script not found${NC}"
                fi
                exit 1
            fi
            ;;
        "detect")
            if declare -f detect_project_stack > /dev/null; then
                local project_dir="${1:-$(pwd)}"

                # Start progress indicator if available
                if declare -f start_progress > /dev/null; then
                    start_progress "Detecting project stack: $project_dir" "spinner"
                else
                    echo -e "${CYAN}🔍 Detecting project stack: $project_dir${NC}"
                fi

                if result=$(detect_project_stack "$project_dir"); then
                    if declare -f stop_progress > /dev/null; then
                        stop_progress
                    fi

                    local stack_id tech_stack project_type confidence
                    IFS='|' read -r stack_id tech_stack project_type confidence <<< "$result"

                    if declare -f show_success > /dev/null; then
                        show_success "Detected: $tech_stack"
                    else
                        echo -e "${GREEN}✅ Detected: $tech_stack${NC}"
                    fi
                    echo -e "${BLUE}   Type: $project_type${NC}"
                    echo -e "${YELLOW}   Confidence: $confidence%${NC}"
                else
                    if declare -f stop_progress > /dev/null; then
                        stop_progress
                    fi
                    if declare -f show_warning > /dev/null; then
                        show_warning "Unknown stack detected"
                        show_info "Run 'claude-ally contribute' to add this stack"
                    else
                        echo -e "${YELLOW}⚠️ Unknown stack detected${NC}"
                        echo -e "${CYAN}💡 Run 'claude-ally contribute' to add this stack${NC}"
                    fi
                fi
            else
                echo -e "${RED}❌ Stack detector not available${NC}"
                exit 1
            fi
            ;;
        "contribute")
            if [[ -f "$SCRIPT_DIR/lib/contribute-stack.sh" ]]; then
                local project_dir="${1:-$(pwd)}"
                local project_name="${2:-$(basename "$project_dir")}"
                bash "$SCRIPT_DIR/lib/contribute-stack.sh" "$project_dir" "$project_name" "$SCRIPT_DIR"
            else
                echo -e "${RED}❌ Contribution script not found${NC}"
                exit 1
            fi
            ;;
        "validate")
            if [[ -f "$SCRIPT_DIR/lib/validate.sh" ]]; then
                local file_path="${1}"
                if [[ -z "$file_path" ]]; then
                    echo -e "${RED}❌ Please specify a file to validate${NC}"
                    echo -e "${CYAN}Usage: claude-ally.sh validate <file>${NC}"
                    exit 1
                fi
                bash "$SCRIPT_DIR/lib/validate.sh" "$file_path"
            else
                echo -e "${RED}❌ Validation script not found${NC}"
                exit 1
            fi
            ;;
        "version")
            show_version
            ;;
        "help"|"--help"|"-h")
            show_help
            ;;
        *)
            echo -e "${RED}❌ Unknown command: $command${NC}"
            echo ""
            show_help
            exit 1
            ;;
    esac
}

# Removed complex cleanup since we simplified modules

# Run main function if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
