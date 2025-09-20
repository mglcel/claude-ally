#!/bin/bash
#
# Claude-Ally - Configure Claude with your project's tech stack
# Automatically detects your tech stack and creates project-specific Claude configuration
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
            # shellcheck source=/dev/null
            source "$SCRIPT_DIR/$module" 2>/dev/null || echo "Warning: Failed to load $module"
        fi
    done
}

# Show version information
show_version() {
    echo -e "${BOLD}Claude-Ally - Configure Claude with your project's tech stack${NC}"
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
    echo -e "${BOLD}Claude-Ally - Configure Claude with your project's tech stack${NC}"
    echo ""
    echo -e "${CYAN}USAGE:${NC}"
    echo "  claude-ally.sh <command> [directory]"
    echo ""
    echo -e "${CYAN}COMMANDS:${NC}"
    echo "  setup [directory]      Configure Claude for your project"
    echo "  detect [directory]     Show detected technology stack"
    echo "  analyze [directory]    Comprehensive project analysis"
    echo "  contribute [directory] Add your stack to the community"
    echo "  validate              Validate system installation"
    echo "  version               Show version information"
    echo "  help                  Show this help message"
    echo ""
    echo -e "${CYAN}EXAMPLES:${NC}"
    echo -e "  ${GREEN}# Basic usage (run from project directory)${NC}"
    echo "  claude-ally.sh setup"
    echo "  claude-ally.sh detect"
    echo ""
    echo -e "  ${GREEN}# Specify project directory${NC}"
    echo "  claude-ally.sh setup /path/to/project"
    echo "  claude-ally.sh detect /path/to/project"
    echo ""
    echo -e "  ${GREEN}# Community contribution${NC}"
    echo "  claude-ally.sh contribute                # Current directory"
    echo "  claude-ally.sh contribute /path/to/novel-stack"
    echo ""
    echo -e "  ${GREEN}# System management${NC}"
    echo "  claude-ally.sh validate                  # Check installation"
    echo ""
    echo -e "${CYAN}SUPPORTED STACKS:${NC}"
    echo "  • Next.js + AI/LLM (TypeScript, OpenAI, Anthropic)"
    echo "  • Python AI/ML (FastAPI, TensorFlow, PyTorch)"
    echo "  • Cordova Mobile Apps (with Maps integration)"
    echo "  • Bash CLI Tools"
    echo "  • And more... (contribute new stacks!)"
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
    local opt_modules=("lib/utilities.sh")
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
    if [[ -f "$HOME/.claude-ally/config.json" ]]; then
        # Source utilities for validation
        if [[ -f "$SCRIPT_DIR/lib/utilities.sh" ]]; then
            source "$SCRIPT_DIR/lib/utilities.sh"
            if validate_basic_config "$HOME/.claude-ally/config.json"; then
                echo -e "  ✅ Configuration valid"
            else
                echo -e "  ⚠️ Configuration issues detected"
            fi
        else
            echo -e "  ⚠️ Configuration validation not available"
        fi
    else
        echo -e "  ⚠️ No configuration file found"
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

                echo -e "${CYAN}🔍 Detecting project stack: $project_dir${NC}"

                if result=$(detect_project_stack "$project_dir"); then

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
        "analyze")
            local project_dir="${1:-$(pwd)}"
            echo -e "${CYAN}🔍 Comprehensive Project Analysis: $project_dir${NC}"
            echo ""

            # Source utilities for enhanced output
            if [[ -f "$SCRIPT_DIR/lib/utilities.sh" ]]; then
                source "$SCRIPT_DIR/lib/utilities.sh"
            fi

            # 1. Basic project info
            echo -e "${BOLD}📋 Project Information${NC}"
            echo "   Directory: $project_dir"

            # Try to get project name from config files
            local project_name=""
            if [[ -f "$project_dir/package.json" ]] && command_exists jq; then
                project_name=$(jq -r '.name // empty' "$project_dir/package.json" 2>/dev/null)
            elif [[ -f "$project_dir/package.json" ]]; then
                project_name=$(grep -o '"name"[[:space:]]*:[[:space:]]*"[^"]*"' "$project_dir/package.json" 2>/dev/null | cut -d'"' -f4)
            elif [[ -f "$project_dir/Cargo.toml" ]]; then
                project_name=$(grep -E '^name[[:space:]]*=' "$project_dir/Cargo.toml" 2>/dev/null | cut -d'=' -f2 | tr -d '"' | xargs)
            fi

            if [[ -n "$project_name" ]]; then
                echo "   Name: $project_name (from config)"
            else
                echo "   Name: $(basename "$project_dir") (directory name)"
            fi
            if [[ -d "$project_dir/.git" ]]; then
                local git_remote
                git_remote=$(cd "$project_dir" && git remote get-url origin 2>/dev/null || echo "No remote")
                echo "   Git: $git_remote"
            fi
            echo ""

            # 2. Stack detection
            echo -e "${BOLD}🔧 Technology Stack${NC}"
            if declare -f detect_project_stack > /dev/null; then
                if result=$(detect_project_stack "$project_dir"); then
                    local stack_id tech_stack project_type confidence
                    IFS='|' read -r stack_id tech_stack project_type confidence <<< "$result"
                    echo "   Stack: $tech_stack"
                    echo "   Type: $project_type"
                    echo "   Confidence: $confidence%"
                else
                    echo "   Stack: Unknown (consider contributing!)"
                fi
            else
                echo "   Stack detector not available"
            fi
            echo ""

            # 3. File analysis
            echo -e "${BOLD}📁 Project Structure${NC}"
            local file_count
            local dir_count
            file_count=$(find "$project_dir" -type f 2>/dev/null | wc -l | tr -d ' ')
            dir_count=$(find "$project_dir" -type d 2>/dev/null | wc -l | tr -d ' ')
            echo "   Files: $file_count"
            echo "   Directories: $dir_count"
            if command_exists du; then
                local size
                size=$(du -sh "$project_dir" 2>/dev/null | cut -f1)
                echo "   Size: $size"
            fi
            echo ""

            # 4. Configuration files
            echo -e "${BOLD}⚙️  Configuration Files${NC}"
            local config_files=("package.json" "requirements.txt" "Cargo.toml" "go.mod" "pom.xml" "build.gradle" "Makefile" "Dockerfile" ".gitignore")
            for config in "${config_files[@]}"; do
                if [[ -f "$project_dir/$config" ]]; then
                    echo "   ✅ $config"
                fi
            done
            echo ""

            # 5. Claude setup status
            echo -e "${BOLD}🤖 Claude Integration${NC}"
            if [[ -f "$project_dir/CLAUDE.md" ]]; then
                local claude_size
                claude_size=$(wc -l < "$project_dir/CLAUDE.md" 2>/dev/null || echo 0)
                echo "   ✅ CLAUDE.md exists ($claude_size lines)"
            else
                echo "   ❌ CLAUDE.md not found"
                echo "   💡 Run 'claude-ally setup' to create it"
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
