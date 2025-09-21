#!/bin/bash
#
# Claude-Ally Setup Script - Modular Version
# Main orchestration script that coordinates all setup modules
#

set -euo pipefail

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source all setup modules
source "$SCRIPT_DIR/setup-core.sh"
source "$SCRIPT_DIR/setup-claude.sh"
source "$SCRIPT_DIR/setup-ui.sh"
source "$SCRIPT_DIR/setup-config.sh"

# Source stack detector for intelligent project type detection
if [[ -f "$SCRIPT_DIR/stack-detector.sh" ]]; then
    source "$SCRIPT_DIR/stack-detector.sh"
fi

# Global variables for the setup process
PROJECT_NAME=""
PROJECT_TYPE=""
TECH_STACK=""
CRITICAL_ASSETS=""
COMMON_ISSUES=""
CONTRIBUTE_ACCEPTED=false
STACK_IS_UNKNOWN=false

# Main setup function
main() {
    # Initialize
    detect_non_interactive
    print_header
    detect_directories

    # Claude integration
    if check_claude_availability; then
        if ! attempt_automatic_claude_analysis; then
            echo -e "${YELLOW}⚠️  Continuing with manual input${NC}"
        fi
    fi

    # Handle existing CLAUDE.md
    local existing_action
    handle_existing_claude_md
    existing_action=$?

    case $existing_action in
        1)  # Skip setup
            echo -e "${CYAN}📄 Setup skipped - keeping existing CLAUDE.md${NC}"
            exit 0
            ;;
        2)  # Merge mode
            echo -e "${BLUE}🔄 Merge mode selected${NC}"
            # Continue with setup for merging
            ;;
        *)  # Replace or no existing file
            echo -e "${GREEN}✅ Proceeding with setup${NC}"
            ;;
    esac

    # Gather project information
    get_project_info
    get_security_info
    get_technical_info

    # Validate inputs
    if ! validate_inputs "$PROJECT_NAME" "$PROJECT_TYPE" "$TECH_STACK" "$CRITICAL_ASSETS" "$COMMON_ISSUES"; then
        exit 1
    fi

    # Generate prompt
    local prompt_file
    prompt_file=$(generate_prompt "$PROJECT_NAME" "$PROJECT_TYPE" "$TECH_STACK" "$CRITICAL_ASSETS" "$COMMON_ISSUES")

    # Handle merging if requested
    if [[ $existing_action -eq 2 ]]; then
        if merge_claude_md_with_claude "$prompt_file"; then
            echo -e "${GREEN}✅ Merge completed successfully${NC}"
        else
            echo -e "${RED}❌ Merge failed, keeping backup${NC}"
            exit 1
        fi
    else
        # Offer automatic Claude setup
        if offer_automatic_claude_setup "$prompt_file"; then
            if setup_claude_automatically "$prompt_file"; then
                # Success message already printed by setup_claude_automatically
                :
            else
                echo -e "${YELLOW}⚠️  Automatic setup failed, use manual process${NC}"
            fi
        fi
    fi

    # Check for contribution opportunity
    check_stack_and_offer_contribution "$TECH_STACK" "$PROJECT_TYPE"

    # Final instructions
    echo ""
    echo -e "${GREEN}🎉 Setup completed successfully!${NC}"
    echo ""
    echo -e "${CYAN}📋 Next Steps:${NC}"
    echo "1. Review the generated prompt file: $(basename "$prompt_file")"

    if [[ -f "$PROJECT_DIR/CLAUDE.md" ]]; then
        echo "2. ✅ CLAUDE.md has been created/updated"
        echo "3. Start a new Claude conversation and test the enhancement"
    else
        echo "2. Copy the prompt content to Claude to create your CLAUDE.md"
        echo "3. Save Claude's response as CLAUDE.md in your project directory"
    fi

    if [[ "$CONTRIBUTE_ACCEPTED" == "true" ]]; then
        echo "4. 🤝 Automatically running contribution workflow..."
        echo ""

        # Run the contribute command automatically
        local contrib_script="$SCRIPT_DIR/contribute-stack.sh"
        if [[ -f "$contrib_script" ]]; then
            echo -e "${CYAN}🚀 Starting contribution process...${NC}"
            bash "$contrib_script" "$PROJECT_DIR" "$(basename "$PROJECT_DIR")" "$SCRIPT_DIR/.."
        else
            echo -e "${YELLOW}⚠️ Contribution script not found. Please run 'claude-ally contribute' manually.${NC}"
        fi
    fi

    echo ""
    echo -e "${BOLD}Your Claude conversations will now be enhanced with project-specific intelligence!${NC}"
}

# Run main function if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi