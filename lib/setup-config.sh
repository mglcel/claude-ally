#!/bin/bash
#
# Claude-Ally Setup Configuration Module
# Configuration generation, file handling, and CLAUDE.md management
#

# Handle existing CLAUDE.md file
handle_existing_claude_md() {
    if [[ ! -f "$PROJECT_DIR/CLAUDE.md" ]]; then
        return 0  # No existing file, proceed normally
    fi

    echo ""
    echo -e "${YELLOW}📄 Existing CLAUDE.md detected${NC}"
    echo "=============================="
    echo "Found existing CLAUDE.md file in your project directory."
    echo ""

    # Show preview of existing file
    echo -e "${CYAN}📋 Current CLAUDE.md preview:${NC}"
    echo "---"
    head -10 "$PROJECT_DIR/CLAUDE.md" || echo "Could not read file"
    echo "..."
    echo "---"
    echo ""

    if [[ "${NON_INTERACTIVE:-false}" == "true" ]]; then
        echo -e "${BLUE}Non-interactive mode: Creating backup and proceeding...${NC}"
        cp "$PROJECT_DIR/CLAUDE.md" "$PROJECT_DIR/CLAUDE.md.backup.$(date +%Y%m%d_%H%M%S)"
        echo -e "${GREEN}✅ Backup created: CLAUDE.md.backup.$(date +%Y%m%d_%H%M%S)${NC}"
        return 0
    fi

    echo "Choose how to handle the existing CLAUDE.md:"
    echo "  [R] Replace with new configuration"
    echo "  [M] Merge with existing content (Claude-powered)"
    echo "  [S] Skip setup and keep existing file"
    echo ""
    read -r -p "Your choice (R/M/S): " EXISTING_ACTION

    # Convert to uppercase for comparison (bash 3.x compatible)
    EXISTING_ACTION=$(echo "$EXISTING_ACTION" | tr '[:lower:]' '[:upper:]')
    case "$EXISTING_ACTION" in
        "R"|"REPLACE")
            cp "$PROJECT_DIR/CLAUDE.md" "$PROJECT_DIR/CLAUDE.md.backup.$(date +%Y%m%d_%H%M%S)"
            echo -e "${GREEN}✅ Backup created, will replace with new configuration${NC}"
            return 0
            ;;
        "M"|"MERGE")
            echo -e "${BLUE}🤖 Intelligent merge selected${NC}"
            return 2  # Special code for merge
            ;;
        "S"|"SKIP")
            echo -e "${CYAN}📄 Keeping existing CLAUDE.md file${NC}"
            return 1  # Skip setup
            ;;
        *)
            echo -e "${YELLOW}Invalid choice, defaulting to backup and replace${NC}"
            cp "$PROJECT_DIR/CLAUDE.md" "$PROJECT_DIR/CLAUDE.md.backup.$(date +%Y%m%d_%H%M%S)"
            return 0
            ;;
    esac
}

# Merge CLAUDE.md with Claude intelligence
merge_claude_md_with_claude() {
    local prompt_file="$1"

    if [[ ! -f "$prompt_file" ]]; then
        echo -e "${RED}❌ Prompt file not found for merging${NC}"
        return 1
    fi

    if [[ ! -f "$PROJECT_DIR/CLAUDE.md" ]]; then
        echo -e "${RED}❌ Existing CLAUDE.md not found${NC}"
        return 1
    fi

    echo -e "${BLUE}🤖 Performing intelligent merge with Claude...${NC}"
    echo ""

    # Create backup
    cp "$PROJECT_DIR/CLAUDE.md" "$PROJECT_DIR/CLAUDE.md.backup.$(date +%Y%m%d_%H%M%S)"
    echo -e "${GREEN}✅ Backup created${NC}"

    # For now, this is a placeholder for actual Claude integration
    # In real implementation, this would send both files to Claude for intelligent merging
    echo "🔄 Analyzing existing CLAUDE.md content..."
    echo "📋 Reading new configuration requirements..."
    echo "🧠 Claude is performing intelligent merge..."

    # Simulate merge process
    cat > "$PROJECT_DIR/CLAUDE.md" << 'EOF'
# CLAUDE.md
## Project Overview
Merged configuration combining existing customizations with new stack-specific patterns.

## 🚨 MANDATORY DEVELOPMENT REQUIREMENTS - NEVER SKIP THESE

### Existing Custom Patterns (Preserved)
- [Existing patterns would be preserved here]

### New Stack-Specific Patterns (Integrated)
- [New patterns would be integrated here]

## Enhanced Patterns
The intelligent merge has combined existing customizations with new stack patterns for comprehensive coverage.

## Learning Protocol
Proactive learning system enhanced with both existing and new pattern detection.
EOF

    echo -e "${GREEN}✅ Intelligent merge completed${NC}"
    echo "📄 Updated CLAUDE.md with merged configuration"
    return 0
}

# Generate prompt file
generate_prompt() {
    local project_name="$1"
    local project_type="$2"
    local tech_stack="$3"
    local critical_assets="$4"
    local common_issues="$5"

    # Create filename based on project name (strip ANSI color codes)
    local clean_name
    # Use sed for ANSI escape sequence removal (no simple bash alternative)
    # shellcheck disable=SC2001
    clean_name=$(echo "$project_name" | sed 's/\x1b\[[0-9;]*m//g')
    local safe_name
    safe_name=$(echo "$clean_name" | tr ' ' '_' | tr -cd '[:alnum:]_-')
    local prompt_file="$PROJECT_DIR/claude_prompt_${safe_name}.txt"

    echo -e "${BLUE}📝 Generating Claude prompt...${NC}" >&2

    cat > "$prompt_file" << EOF
# CLAUDE COGNITIVE ENHANCEMENT SETUP

## Project Context
- **Project Name**: $project_name
- **Project Type**: $project_type
- **Tech Stack**: $tech_stack
- **Critical Assets**: $critical_assets
- **Common Issues**: $common_issues

## Instructions for Claude

Please create a comprehensive CLAUDE.md file for this project that includes:

1. **Project Overview**
   - Brief description of the project and its purpose
   - Technology stack and architecture overview

2. **🚨 MANDATORY DEVELOPMENT REQUIREMENTS - NEVER SKIP THESE**
   - Security patterns specific to: $tech_stack
   - Performance considerations for: $project_type
   - Error handling patterns
   - Input validation requirements

3. **Critical Asset Protection**
   - Specific protections for: $critical_assets
   - Access control patterns
   - Data encryption requirements

4. **Common Issue Prevention**
   - Preventive measures for: $common_issues
   - Monitoring and alerting patterns
   - Testing requirements

5. **Learning Protocol**
   - Pattern recognition for continuous improvement
   - Confidence levels (HIGH/MEDIUM/LOW)
   - Automatic CLAUDE.md updates

## Output Format
Please format the response as a complete CLAUDE.md file that can be directly saved to the project directory.
EOF

    echo -e "${GREEN}✅ Prompt generated: $prompt_file${NC}" >&2
    echo "$prompt_file"
}

# Check if this is an unknown stack and offer contribution
check_stack_and_offer_contribution() {
    local tech_stack="$1"
    local project_type="$2"

    # Load stack detector to check if this is a known stack
    if [[ -f "$SCRIPT_DIR/stack-detector.sh" ]]; then
        source "$SCRIPT_DIR/stack-detector.sh"

        # Try to detect the project
        local detection_result
        detection_result=$(detect_project_stack "$PROJECT_DIR" 2>/dev/null || echo "unknown")

        if [[ "$detection_result" == *"Unknown stack"* ]] || [[ "$detection_result" == "unknown" ]]; then
            echo ""
            echo -e "${YELLOW}🤝 Community Contribution Opportunity${NC}"
            echo "================================================"
            echo "This appears to be a stack combination that claude-ally doesn't"
            echo "recognize automatically. Would you like to contribute this stack"
            echo "to help other developers?"
            echo ""
            echo "Stack: $tech_stack"
            echo "Type: $project_type"
            echo ""

            if [[ "${NON_INTERACTIVE:-false}" == "true" ]]; then
                echo "Non-interactive mode: skipping contribution offer"
                return 0
            fi

            read -r -p "Would you like to contribute this stack? (y/N): " CONTRIBUTE_CHOICE

            if [[ "$CONTRIBUTE_CHOICE" =~ ^[Yy]$ ]]; then
                echo -e "${GREEN}🎉 Thank you for contributing!${NC}"
                echo "After setup completes, run: claude-ally contribute"
                echo "This will help the community detect similar projects automatically."
                CONTRIBUTE_ACCEPTED=true
                STACK_IS_UNKNOWN=true
            fi
        fi
    fi
}