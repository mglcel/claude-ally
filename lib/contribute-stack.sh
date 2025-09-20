#!/bin/bash
# Stack Contribution Feature
# Helps users contribute new stack detection modules to claude-ally

# Get script directory for sourcing utilities
CONTRIB_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source utilities if available
if [[ -f "$CONTRIB_SCRIPT_DIR/utilities.sh" ]]; then
    source "$CONTRIB_SCRIPT_DIR/utilities.sh"
fi

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# Cross-platform compatibility
detect_os() {
    case "$(uname -s)" in
        Linux*)     echo "linux";;
        Darwin*)    echo "macos";;
        CYGWIN*|MINGW*|MSYS*) echo "windows";;
        *)          echo "unknown";;
    esac
}

# Check if we can call Claude
check_claude_availability() {
    if command -v claude &> /dev/null; then
        return 0
    elif [[ -f "/usr/local/bin/claude" ]] || [[ -f "/usr/bin/claude" ]]; then
        return 0
    else
        return 1
    fi
}

# Analyze project using Claude for new stack detection
analyze_unknown_stack_with_claude() {
    local project_dir="$1"
    local project_name="$2"

    # Create cache key and file
    local cache_key
    cache_key=$(create_cache_key "$project_dir" "$project_name")
    local cache_file="/tmp/claude_analysis_cache_${cache_key}.md"

    # Check if we have a recent analysis (less than 1 hour old)
    if is_cache_valid "$cache_file"; then
        echo -e "${GREEN}🔄 Using cached Claude analysis (found recent analysis for this project)${NC}"
        cat "$cache_file"
        return 0
    fi

    echo -e "${CYAN}🤖 Using Claude to analyze unknown stack...${NC}"

    # Create analysis prompt for Claude
    local analysis_file
    analysis_file="/tmp/stack_analysis_$(date +%s).md"

    cat > "$analysis_file" << EOF
# New Stack Detection Analysis for Claude-Ally

Please analyze this project directory and determine if it represents a technology stack that should be added to claude-ally's detection system.

**Project Directory:** \`$project_dir\`
**Project Name:** $project_name

## Analysis Request:

1. **Stack Identification**: What is the primary technology stack? (e.g., "Svelte + Tauri", "Flutter Web", "Nuxt.js + Supabase")

2. **Detection Patterns**: What files/patterns would reliably identify this stack?
   - Configuration files (package.json patterns, specific configs)
   - Directory structure
   - Dependencies that are unique indicators

3. **Project Type**: What category does this fit? (web-app, mobile-app, desktop-app, ai-ml-service, etc.)

4. **Critical Patterns**: What are the CRITICAL and HIGH_PRIORITY patterns for this stack that Claude should watch for?

5. **Is this worth adding?**: Should this be added to claude-ally? (YES/NO with reasoning)

## Project Files Analysis:
$(find "$project_dir" -maxdepth 2 -name "*.json" -o -name "*.toml" -o -name "*.yaml" -o -name "*.yml" -o -name "*.config.*" -o -name "Dockerfile" -o -name "README*" | head -10)

Please provide a structured analysis that I can use to generate a new stack detection module.

Expected format:
- **STACK_ID**: short-name (e.g., "svelte-tauri")
- **TECH_STACK**: descriptive name (e.g., "Svelte/Tauri Desktop")
- **PROJECT_TYPE**: category
- **CONFIDENCE_PATTERNS**: list of detection patterns
- **WORTH_ADDING**: YES/NO with reasoning
- **DETECTION_CODE**: suggested bash detection logic
EOF

    # Call Claude if available
    if check_claude_availability; then
        echo -e "${BLUE}📝 Calling Claude for analysis...${NC}"

        local claude_result
        if claude_result=$(claude < "$analysis_file" 2>/dev/null); then
            echo -e "${GREEN}✅ Claude analysis completed${NC}"

            # Save to cache for future use
            echo "$claude_result" > "$cache_file"

            # Also save to timestamped file for debugging
            echo "$claude_result" > "/tmp/claude_stack_analysis_$(date +%s).md"

            echo "$claude_result"
            rm -f "$analysis_file"
            return 0
        else
            echo -e "${RED}❌ Failed to call Claude${NC}"
            rm -f "$analysis_file"
            return 1
        fi
    else
        echo -e "${YELLOW}⚠️ Claude not available, manual analysis needed${NC}"
        echo "Analysis prompt saved to: $analysis_file"
        echo "Please copy this file content to Claude manually and analyze the project."
        return 1
    fi
}

# Generate stack detection module from Claude analysis
generate_stack_module() {
    local stack_id="$1"
    local tech_stack="$2"
    local project_type="$3"
    local detection_patterns="$4"
    local output_dir="$5"

    local module_file="$output_dir/stacks/${stack_id}.sh"

    echo -e "${CYAN}📝 Generating stack module: $module_file${NC}"

    mkdir -p "$output_dir/stacks"

    cat > "$module_file" << EOF
#!/bin/bash
# $tech_stack Stack Detection
# Auto-generated contribution for claude-ally

detect_${stack_id//-/_}() {
    local project_dir="\$1"
    local confidence=0
    local tech_stack="$tech_stack"
    local project_type="$project_type"

    # TODO: Implement detection logic based on patterns:
    # $detection_patterns

    # Example detection logic (customize based on analysis):
    # if [[ -f "\$project_dir/specific-config.json" ]]; then
    #     confidence=\$((confidence + 40))
    # fi

    # Minimum confidence threshold
    if [[ \$confidence -ge 50 ]]; then
        echo "${stack_id}|\$tech_stack|\$project_type|\$confidence"
        return 0
    fi

    return 1
}

get_${stack_id//-/_}_patterns() {
    cat << 'EOL'
${tech_stack^^} PATTERNS
${tech_stack//-/_}_Patterns (HIGH - Technology Specific):
  CRITICAL_${tech_stack^^}:
    - "pattern1" → Description of what to validate
    - "pattern2" → Description of what to check
  HIGH_PRIORITY:
    - "pattern3" → Additional validation needed
    - "pattern4" → Performance or security check
EOL
}

get_${stack_id//-/_}_assets() {
    echo "technology-specific assets, configuration files, API keys"
}

get_${stack_id//-/_}_requirements() {
    echo "technology-specific requirements"
}

get_${stack_id//-/_}_issues() {
    echo "common technology-specific issues"
}
EOF

    chmod +x "$module_file"
    echo -e "${GREEN}✅ Module generated: $module_file${NC}"
    return 0
}

# Propose pull request contribution
propose_contribution() {
    local project_dir="$1"
    local project_name="$2"
    local claude_ally_dir="$3"
    local claude_result="$4"  # Optional: existing Claude analysis result

    echo ""
    echo -e "${PURPLE}🚀 STACK CONTRIBUTION OPPORTUNITY DETECTED${NC}"
    echo -e "${BOLD}================================================${NC}"
    echo ""
    echo -e "Project: ${BOLD}$project_name${NC}"
    echo -e "Location: $project_dir"
    echo ""
    echo -e "${CYAN}It looks like this project uses a technology stack that isn't yet"
    echo -e "supported by claude-ally's automatic detection system!${NC}"
    echo ""
    echo -e "${YELLOW}Would you like to contribute this stack detection to claude-ally?${NC}"
    echo -e "This would help other developers using similar technology stacks."
    echo ""

    local contribute_choice
    read -r -p "Contribute to claude-ally? (Y/n): " contribute_choice || {
        echo -e "\n\033[1;33m⚠️  Input interrupted by user.\033[0m"
        exit 130
    }

    if [[ "$contribute_choice" =~ ^[Nn] ]]; then
        echo -e "${BLUE}No problem! Continuing with setup...${NC}"
        return 1
    fi

    echo ""
    echo -e "${CYAN}🔍 Analyzing project for contribution...${NC}"

    # Use existing analysis or perform new analysis
    local analysis_result="$claude_result"
    if [[ -n "$claude_result" ]]; then
        echo -e "${GREEN}✅ Using existing Claude analysis${NC}"
        analysis_result="$claude_result"
    elif analyze_unknown_stack_with_claude "$project_dir" "$project_name"; then
        echo ""
        echo -e "${GREEN}✅ Stack analysis completed!${NC}"
    else
        echo -e "${RED}❌ Failed to analyze stack${NC}"
        return 1
    fi

    # Ask user about generating contribution files (for both existing and new analysis)
    echo ""
    echo -e "${YELLOW}Based on the analysis, would you like to generate the contribution files?${NC}"

    local generate_choice
    read -r -p "Generate contribution files? (Y/n): " generate_choice || {
        echo -e "\n\033[1;33m⚠️  Input interrupted by user.\033[0m"
        exit 130
    }

    if [[ ! "$generate_choice" =~ ^[Nn] ]]; then
        # Generate contribution template
        local contrib_dir
        contrib_dir="/tmp/claude-ally-contribution-$(date +%s)"
        mkdir -p "$contrib_dir"

        echo -e "${CYAN}📝 Generating contribution template...${NC}"

        # Create contribution guide
        cat > "$contrib_dir/CONTRIBUTION_GUIDE.md" << 'EOF'
# Stack Detection Contribution Guide

Thank you for contributing a new stack detection module to claude-ally!

## Files Generated:
- `stacks/[stack-name].sh` - Detection module
- `CONTRIBUTION_GUIDE.md` - This guide

## Next Steps:

1. **Review and customize** the generated detection module
2. **Test** the detection logic with your project
3. **Fork** the claude-ally repository on GitHub
4. **Add** your stack module to the `stacks/` directory
5. **Update** the README.md with your new stack support
6. **Create** a pull request with your contribution

## Testing Your Module:

```bash
# Source your module
source stacks/your-stack.sh

# Test detection
detect_your_stack "/path/to/test/project"
```

## Pull Request Checklist:

- [ ] Detection logic works reliably
- [ ] Patterns are comprehensive and specific
- [ ] Module follows the established format
- [ ] README.md updated with new stack support
- [ ] Tested with multiple projects of this type

## Contact:

Feel free to open an issue on GitHub if you need help with your contribution!
EOF

        echo -e "${GREEN}✅ Contribution template created at: $contrib_dir${NC}"

        # Check if Claude recommends adding this stack
        local worth_adding
        worth_adding=$(echo "$analysis_result" | grep -i "WORTH_ADDING" | sed 's/.*WORTH_ADDING[^:]*:[[:space:]]*\(.*\)$/\1/' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//' | head -1)
        worth_adding=$(echo "$worth_adding" | tr '[:lower:]' '[:upper:]' | sed 's/^["\*]*//;s/["\*]*$//')

        if [[ "$worth_adding" =~ ^NO ]]; then
            echo ""
            echo -e "${YELLOW}ℹ️ Claude analysis suggests this project may not be suitable for contribution${NC}"
            echo -e "${CYAN}Reason: Stack appears too minimal or generic for automated detection${NC}"
            echo ""
            echo -e "${BLUE}If you believe this assessment is incorrect, you can still contribute manually:${NC}"
            echo -e "1. Review the analysis in the contribution template"
            echo -e "2. Customize the detection logic for your specific use case"
            echo -e "3. Fork claude-ally on GitHub: https://github.com/mglcel/claude-ally/fork"
            echo -e "4. Submit a pull request with justification for why this stack should be supported"
            return 0
        fi

        # Extract contribution details for GitHub PR
        local stack_info
        if stack_info=$(echo "$analysis_result" | grep -A5 "STACK_ID\|TECH_STACK\|PROJECT_TYPE"); then
            local stack_id tech_stack project_type

            # Parse Claude's analysis - handle **FIELD**: value format
            stack_id=$(echo "$analysis_result" | grep -i "STACK_ID" | sed 's/.*STACK_ID[^:]*:[[:space:]]*\(.*\)$/\1/' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//' | head -1)
            tech_stack=$(echo "$analysis_result" | grep -i "TECH_STACK" | sed 's/.*TECH_STACK[^:]*:[[:space:]]*\(.*\)$/\1/' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//' | head -1)
            project_type=$(echo "$analysis_result" | grep -i "PROJECT_TYPE" | sed 's/.*PROJECT_TYPE[^:]*:[[:space:]]*\(.*\)$/\1/' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//' | head -1)

            # Clean up any remaining quotes or parentheses
            stack_id=$(echo "$stack_id" | sed 's/^["\(]*//;s/["\)]*$//')
            tech_stack=$(echo "$tech_stack" | sed 's/^["\(]*//;s/["\)]*$//')
            project_type=$(echo "$project_type" | sed 's/^["\(]*//;s/["\)]*$//')

            # Sanitize stack_id for filename and shell variable safety
            stack_id=$(echo "$stack_id" | sed 's/[^a-zA-Z0-9-]/-/g' | sed 's/--*/-/g' | sed 's/^-\|-$//g' | tr '[:upper:]' '[:lower:]')

            # Ensure stack_id is not empty after sanitization
            if [[ -z "$stack_id" ]] || [[ "$stack_id" == "n-a" ]] || [[ "$stack_id" == "unknown" ]]; then
                stack_id="unknown-stack"
            fi


            if [[ -n "$stack_id" ]] && [[ -n "$tech_stack" ]] && [[ "$stack_id" != "unknown-stack" ]]; then
                echo ""
                echo -e "${PURPLE}🚀 GITHUB INTEGRATION AVAILABLE${NC}"
                echo -e "${BOLD}================================${NC}"

                # Check if GitHub PR script exists
                if [[ -f "$claude_ally_dir/lib/github-pr.sh" ]]; then
                    echo -e "${YELLOW}Would you like to create a pull request directly to the claude-ally GitHub repository?${NC}"
                    echo -e "${CYAN}This will automatically:${NC}"
                    echo "  🍴 Fork the repository"
                    echo "  📥 Clone your fork"
                    echo "  🔧 Create your stack detection module"
                    echo "  📤 Push changes"
                    echo "  🔄 Create pull request"
                    echo ""

                    local github_pr_choice
                    read -r -p "Create GitHub pull request automatically? (Y/n): " github_pr_choice || {
                        echo -e "\n\033[1;33m⚠️  Input interrupted by user.\033[0m"
                        exit 130
                    }

                    if [[ ! "$github_pr_choice" =~ ^[Nn] ]]; then
                        echo ""
                        if bash "$claude_ally_dir/lib/github-pr.sh" "$stack_id" "$tech_stack" "$project_type" "Auto-detected patterns" "$project_dir" "$project_name"; then
                            echo -e "${GREEN}🎉 Your contribution has been submitted to GitHub!${NC}"
                            return 0
                        else
                            echo -e "${YELLOW}⚠️ Automated GitHub PR failed, providing manual instructions...${NC}"
                        fi
                    fi
                fi
            fi
        fi

        echo ""
        echo -e "${CYAN}Manual contribution options:${NC}"
        echo -e "1. Review files in: ${BOLD}$contrib_dir${NC}"
        echo -e "2. Customize the detection logic for your stack"
        echo -e "3. Fork claude-ally on GitHub: https://github.com/mglcel/claude-ally/fork"
        echo -e "4. Submit a pull request with your new stack module"
        echo ""

        # Open directory if possible
        local os_type
        os_type=$(detect_os)
        case "$os_type" in
            "macos")
                open "$contrib_dir" 2>/dev/null || true
                ;;
            "linux")
                xdg-open "$contrib_dir" 2>/dev/null || true
                ;;
            "windows")
                explorer "$contrib_dir" 2>/dev/null || true
                ;;
        esac

        return 0
    else
        echo -e "${YELLOW}⚠️ Automated analysis not available${NC}"
        echo -e "${CYAN}You can still contribute manually:${NC}"
        echo ""
        echo -e "1. Analyze your project's unique technology patterns"
        echo -e "2. Create a detection module based on the claude-ally format"
        echo -e "3. Fork the repository and submit a pull request"
        echo ""
        echo -e "${BLUE}See existing modules in the stacks/ directory for examples${NC}"
        return 1
    fi
}

# Main contribution workflow
main() {
    local project_dir="${1:-$(pwd)}"
    local project_name="${2:-$(basename "$project_dir")}"
    local claude_ally_dir="${3:-$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}"

    echo -e "${CYAN}🔍 Checking for contribution opportunities...${NC}"

    # Source the stack detector
    source "$claude_ally_dir/lib/stack-detector.sh"

    # Check if this is a known stack
    if detect_project_stack "$project_dir" > /dev/null; then
        echo -e "${GREEN}✅ This stack is already supported by claude-ally${NC}"
        return 0  # Success - stack is already supported
    fi

    # This is an unknown stack - offer to help contribute it
    echo -e "${YELLOW}🚀 Unknown stack detected - let's contribute it!${NC}"

    # Try Claude analysis first if available
    local claude_analysis_result=""
    if check_claude_availability; then
        echo -e "${CYAN}🤖 Claude is available - running automated analysis...${NC}"
        if claude_analysis_result=$(analyze_unknown_stack_with_claude "$project_dir" "$project_name"); then
            echo -e "${GREEN}✅ Claude analysis completed successfully${NC}"
            propose_contribution "$project_dir" "$project_name" "$claude_ally_dir" "$claude_analysis_result"
            return $?
        else
            echo -e "${YELLOW}⚠️ Claude analysis failed, proceeding with manual workflow${NC}"
        fi
    fi

    # Claude not available or failed - offer manual contribution
    echo -e "${BLUE}📝 Setting up manual contribution workflow...${NC}"
    propose_contribution "$project_dir" "$project_name" "$claude_ally_dir"
    return $?
}

# Run if called directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi