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
VERSION="2.2"

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
    echo "  validate [file]       Validate system installation or prompt file"
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
    echo "  claude-ally.sh validate prompt_file.txt # Validate prompt file"
    echo "  claude-ally.sh clean [directory]         # Clear project-specific caches"
}

# Clean project-specific caches and temporary files
clean_caches() {
    local project_dir="${1:-$(pwd)}"
    local project_name
    project_name=$(basename "$project_dir")

    echo -e "${CYAN}🧹 Cleaning claude-ally caches for project: ${BOLD}$project_name${NC}"
    echo -e "${BLUE}📂 Project directory: $project_dir${NC}"
    echo ""

    # Source utilities to get cache key generation
    if [[ -f "$SCRIPT_DIR/lib/utilities.sh" ]]; then
        source "$SCRIPT_DIR/lib/utilities.sh"
    else
        # Fallback implementation
        create_cache_key() {
            local proj_dir="$1"
            local proj_name="$2"
            echo "${proj_dir}_${proj_name}" | md5sum 2>/dev/null | cut -d' ' -f1 || echo "${proj_dir}_${proj_name}" | shasum -a 256 | cut -d' ' -f1
        }
    fi

    # Generate project-specific cache key
    local cache_key
    cache_key=$(create_cache_key "$project_dir" "$project_name")

    echo -e "${YELLOW}🔑 Project cache key: ${cache_key}${NC}"
    echo ""

    local total_removed=0
    local total_size=0

    # Function to safely remove files with reporting
    clean_pattern() {
        local pattern="$1"
        local description="$2"
        local files_found=0
        local size_freed=0

        # Use ls with glob pattern (more reliable on macOS)
        local matching_files
        matching_files=$(ls /tmp/"$pattern" 2>/dev/null || true)

        if [[ -n "$matching_files" ]]; then
            # Calculate total size and count files
            for file in $matching_files; do
                if [[ -f "$file" ]]; then
                    local file_size
                    file_size=$(stat -f%z "$file" 2>/dev/null || stat -c%s "$file" 2>/dev/null || echo "0")
                    size_freed=$((size_freed + file_size))
                    files_found=$((files_found + 1))
                fi
            done

            # Remove the files
            rm -f "$matching_files" 2>/dev/null || true

            # Format size for display
            local size_display
            if [[ $size_freed -gt 1048576 ]]; then
                size_display="$(echo "scale=1; $size_freed/1048576" | bc 2>/dev/null || echo "0")MB"
            elif [[ $size_freed -gt 1024 ]]; then
                size_display="$(echo "scale=1; $size_freed/1024" | bc 2>/dev/null || echo "0")KB"
            else
                size_display="${size_freed}B"
            fi

            echo -e "  ${GREEN}✅${NC} $description: ${files_found} files (${size_display})"
            total_removed=$((total_removed + files_found))
            total_size=$((total_size + size_freed))
        else
            echo -e "  ${BLUE}ℹ️${NC} $description: No files found"
        fi
    }

    # Function to clean directories
    clean_directories() {
        local pattern="$1"
        local description="$2"
        local dirs_found=0

        while IFS= read -r -d '' dir; do
            if [[ -d "$dir" ]]; then
                dirs_found=$((dirs_found + 1))
                rm -rf "$dir" 2>/dev/null || true
            fi
        done < <(find /tmp -name "$pattern" -type d -maxdepth 1 -print0 2>/dev/null)

        if [[ $dirs_found -gt 0 ]]; then
            echo -e "  ${GREEN}✅${NC} $description: ${dirs_found} directories"
        else
            echo -e "  ${BLUE}ℹ️${NC} $description: No directories found"
        fi
    }

    # Clean project-specific Claude analysis caches
    clean_pattern "claude_analysis_cache_${cache_key}.md" "Project-specific Claude analysis cache"

    # Clean project-specific temporary analysis files (broader pattern for timestamped files)
    # Look for files that might contain the project path or name
    echo -e "  ${YELLOW}🔍${NC} Scanning for project-related analysis files..."
    local project_analysis_files=0
    local project_analysis_size=0

    # Find analysis files that might be related to this project
    for file in /tmp/claude_stack_analysis_*.md /tmp/stack_analysis_*.md; do
        if [[ -f "$file" ]]; then
            # Check if file content or name relates to this project
            if grep -q "$project_dir\|$project_name" "$file" 2>/dev/null; then
                local file_size
                file_size=$(stat -f%z "$file" 2>/dev/null || stat -c%s "$file" 2>/dev/null || echo "0")
                project_analysis_size=$((project_analysis_size + file_size))
                project_analysis_files=$((project_analysis_files + 1))
                rm -f "$file" 2>/dev/null || true
            fi
        fi
    done

    if [[ $project_analysis_files -gt 0 ]]; then
        local size_display
        if [[ $project_analysis_size -gt 1048576 ]]; then
            size_display="$(echo "scale=1; $project_analysis_size/1048576" | bc 2>/dev/null || echo "0")MB"
        elif [[ $project_analysis_size -gt 1024 ]]; then
            size_display="$(echo "scale=1; $project_analysis_size/1024" | bc 2>/dev/null || echo "0")KB"
        else
            size_display="${project_analysis_size}B"
        fi
        echo -e "  ${GREEN}✅${NC} Project-related analysis files: ${project_analysis_files} files (${size_display})"
        total_removed=$((total_removed + project_analysis_files))
        total_size=$((total_size + project_analysis_size))
    else
        echo -e "  ${BLUE}ℹ️${NC} Project-related analysis files: No files found"
    fi

    # Clean suggestions files that might be related to this project
    echo -e "  ${YELLOW}🔍${NC} Scanning for project-related suggestion files..."
    local project_suggestion_files=0
    local project_suggestion_size=0

    for file in /tmp/claude_suggestions_*.txt; do
        if [[ -f "$file" ]]; then
            # Check file modification time and content for project relation
            if grep -q "$project_dir\|$project_name" "$file" 2>/dev/null; then
                local file_size
                file_size=$(stat -f%z "$file" 2>/dev/null || stat -c%s "$file" 2>/dev/null || echo "0")
                project_suggestion_size=$((project_suggestion_size + file_size))
                project_suggestion_files=$((project_suggestion_files + 1))
                rm -f "$file" 2>/dev/null || true
            fi
        fi
    done

    if [[ $project_suggestion_files -gt 0 ]]; then
        local size_display
        if [[ $project_suggestion_size -gt 1048576 ]]; then
            size_display="$(echo "scale=1; $project_suggestion_size/1048576" | bc 2>/dev/null || echo "0")MB"
        elif [[ $project_suggestion_size -gt 1024 ]]; then
            size_display="$(echo "scale=1; $project_suggestion_size/1024" | bc 2>/dev/null || echo "0")KB"
        else
            size_display="${project_suggestion_size}B"
        fi
        echo -e "  ${GREEN}✅${NC} Project-related suggestion files: ${project_suggestion_files} files (${size_display})"
        total_removed=$((total_removed + project_suggestion_files))
        total_size=$((total_size + project_suggestion_size))
    else
        echo -e "  ${BLUE}ℹ️${NC} Project-related suggestion files: No files found"
    fi

    # Clean project-specific temporary directories (contribution workflows)
    echo -e "  ${YELLOW}🔍${NC} Scanning for project-related temporary directories..."
    local project_temp_dirs=0

    for dir in /tmp/claude-ally-contribution-*; do
        if [[ -d "$dir" ]]; then
            # Check if directory contains files related to this project
            if find "$dir" -type f -exec grep -l "$project_dir\|$project_name" {} \; 2>/dev/null | head -1 | grep -q .; then
                rm -rf "$dir" 2>/dev/null || true
                project_temp_dirs=$((project_temp_dirs + 1))
            fi
        fi
    done

    if [[ $project_temp_dirs -gt 0 ]]; then
        echo -e "  ${GREEN}✅${NC} Project-related temporary directories: ${project_temp_dirs} directories"
    else
        echo -e "  ${BLUE}ℹ️${NC} Project-related temporary directories: No directories found"
    fi

    echo ""
    echo -e "${CYAN}📊 Cleanup Summary:${NC}"

    # Format total size for display
    local total_size_display
    if [[ $total_size -gt 1048576 ]]; then
        total_size_display="$(echo "scale=1; $total_size/1048576" | bc 2>/dev/null || echo "0")MB"
    elif [[ $total_size -gt 1024 ]]; then
        total_size_display="$(echo "scale=1; $total_size/1024" | bc 2>/dev/null || echo "0")KB"
    else
        total_size_display="${total_size}B"
    fi

    echo "  Files removed: ${total_removed}"
    echo "  Space freed: ${total_size_display}"
    echo ""

    if [[ $total_removed -gt 0 ]]; then
        echo -e "${GREEN}✨ Cache cleanup completed successfully!${NC}"
        echo -e "${YELLOW}💡 Next analysis runs will be fresh and up-to-date${NC}"
    else
        echo -e "${GREEN}✨ No cleanup needed - system is already clean!${NC}"
    fi
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
            local project_dir="${1:-$(pwd)}"
            echo -e "${CYAN}🔍 Detecting project stack: $project_dir${NC}"

            # Load Claude integration module
            if [[ -f "$SCRIPT_DIR/lib/setup-claude.sh" ]]; then
                source "$SCRIPT_DIR/lib/setup-claude.sh"
            fi

            # Always try Claude analysis first (bypass cache)
            local claude_detected=false
            if declare -f perform_claude_project_analysis > /dev/null; then
                echo -e "${BLUE}🤖 Using Claude AI for stack detection (bypassing cache)${NC}"
                unset CLAUDE_DETECTED_STACK  # Clear any cached results

                if perform_claude_project_analysis "$project_dir"; then
                    if [[ -n "${CLAUDE_DETECTED_STACK:-}" ]]; then
                        echo -e "${GREEN}✅ Claude detected: $CLAUDE_DETECTED_STACK${NC}"
                        echo -e "${BLUE}   Source: Claude AI Analysis${NC}"
                        echo -e "${YELLOW}   Confidence: HIGH${NC}"
                        claude_detected=true
                    fi
                fi
            fi

            # Fall back to static detection only if Claude fails
            if [[ "$claude_detected" != "true" ]]; then
                echo -e "${YELLOW}⚠️ Claude analysis unavailable, falling back to static detection${NC}"

                if declare -f detect_project_stack > /dev/null; then
                    if result=$(detect_project_stack "$project_dir"); then
                        local stack_id tech_stack project_type confidence
                        IFS='|' read -r stack_id tech_stack project_type confidence <<< "$result"

                        echo -e "${GREEN}✅ Detected: $tech_stack${NC}"
                        echo -e "${BLUE}   Type: $project_type${NC}"
                        echo -e "${YELLOW}   Confidence: $confidence%${NC}"
                        echo -e "${CYAN}   Source: Static Pattern Detection${NC}"
                    else
                        echo -e "${YELLOW}⚠️ Unknown stack detected${NC}"
                        echo -e "${CYAN}💡 Run 'claude-ally contribute' to add this stack${NC}"
                    fi
                else
                    echo -e "${RED}❌ No detection methods available${NC}"
                    exit 1
                fi
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
            local file_path="${1}"
            if [[ -n "$file_path" ]]; then
                # File validation mode - validate a specific prompt file
                if [[ -f "$SCRIPT_DIR/lib/validate.sh" ]]; then
                    bash "$SCRIPT_DIR/lib/validate.sh" "$file_path"
                else
                    echo -e "${RED}❌ Prompt validation script not found${NC}"
                    exit 1
                fi
            else
                # System validation mode - validate installation
                echo -e "${CYAN}🔍 Validating Claude-Ally System Installation${NC}"
                echo "============================================="
                echo ""

                local validation_errors=0

                # Check core files
                echo -e "${BLUE}📂 Checking core files...${NC}"
                if [[ -f "$SCRIPT_DIR/claude-ally.sh" ]]; then
                    echo -e "${GREEN}✅ Main script: claude-ally.sh${NC}"
                else
                    echo -e "${RED}❌ Missing: claude-ally.sh${NC}"
                    ((validation_errors++))
                fi

                # Check lib directory and modules
                echo -e "${BLUE}📚 Checking library modules...${NC}"
                local required_modules=(
                    "lib/stack-detector.sh"
                    "lib/setup-claude.sh"
                    "lib/contribute-stack.sh"
                    "lib/setup-config.sh"
                )

                for module in "${required_modules[@]}"; do
                    if [[ -f "$SCRIPT_DIR/$module" ]]; then
                        echo -e "${GREEN}✅ Module: $module${NC}"
                    else
                        echo -e "${RED}❌ Missing: $module${NC}"
                        ((validation_errors++))
                    fi
                done

                # Check stacks directory
                echo -e "${BLUE}🏗️  Checking stack detectors...${NC}"
                if [[ -d "$SCRIPT_DIR/stacks" ]]; then
                    local stack_count
                    stack_count=$(find "$SCRIPT_DIR/stacks" -name "*.sh" -type f 2>/dev/null | wc -l | tr -d '[:space:]')
                    echo -e "${GREEN}✅ Stacks directory found with $stack_count detectors${NC}"
                else
                    echo -e "${RED}❌ Missing: stacks directory${NC}"
                    ((validation_errors++))
                fi

                # Check system dependencies
                echo -e "${BLUE}🔧 Checking system dependencies...${NC}"
                local deps=("bash" "git" "grep" "find" "sed")
                for dep in "${deps[@]}"; do
                    if command -v "$dep" &> /dev/null; then
                        echo -e "${GREEN}✅ System dependency: $dep${NC}"
                    else
                        echo -e "${RED}❌ Missing dependency: $dep${NC}"
                        ((validation_errors++))
                    fi
                done

                # Check optional dependencies
                echo -e "${BLUE}🌟 Checking optional dependencies...${NC}"
                local opt_deps=("claude" "gh" "jq")
                for dep in "${opt_deps[@]}"; do
                    if command -v "$dep" &> /dev/null; then
                        echo -e "${GREEN}✅ Optional dependency: $dep${NC}"
                    else
                        echo -e "${YELLOW}⚠️  Optional dependency not found: $dep${NC}"
                    fi
                done

                # Summary
                echo ""
                if [[ $validation_errors -eq 0 ]]; then
                    echo -e "${GREEN}✅ System validation passed!${NC}"
                    echo "Claude-Ally is properly installed and ready to use."
                else
                    echo -e "${RED}❌ System validation failed with $validation_errors errors${NC}"
                    echo "Please check the missing files and dependencies above."
                    exit 1
                fi
            fi
            ;;
        "clean")
            local project_dir="${1:-$(pwd)}"
            clean_caches "$project_dir"
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
