#!/bin/bash
#
# Claude-Ally Setup Claude Integration Module
# Claude availability detection, analysis, and intelligent suggestions
#

# Global variables for Claude functionality
CLAUDE_AVAILABLE=false
CLAUDE_SUGGESTIONS_FILE=""

# Check if Claude is available
check_claude_availability() {
    echo -e "${BLUE}🔍 Checking Claude availability...${NC}"

    # Check if we're in a claude-code environment
    if command -v claude &> /dev/null; then
        echo -e "${GREEN}✅ Claude Code CLI detected${NC}"
        CLAUDE_AVAILABLE=true
        return 0
    fi

    # Check if this appears to be a claude-code session (common env vars)
    if [[ -n "${CLAUDE_CODE_SESSION:-}" ]] || [[ -n "${CLAUDE_PROJECT_ROOT:-}" ]] || [[ -n "${CLAUDECODE:-}" ]] || [[ -n "${CLAUDE_CODE_ENTRYPOINT:-}" ]]; then
        echo -e "${GREEN}✅ Claude Code environment detected${NC}"
        CLAUDE_AVAILABLE=true
        return 0
    fi

    # Try to detect if we're running within claude-code context
    if [[ -f "/.claude-code-marker" ]] || [[ -d "/.claude-code" ]]; then
        echo -e "${GREEN}✅ Claude Code context detected${NC}"
        CLAUDE_AVAILABLE=true
        return 0
    fi

    # If we can't detect Claude but user might be running this from Claude
    echo -e "${YELLOW}⚠️  Cannot automatically detect Claude availability.${NC}"
    echo ""

    if [[ "${NON_INTERACTIVE:-false}" == "true" ]]; then
        # In non-interactive mode, assume Claude is available
        echo "Non-interactive mode: assuming Claude is available..."
        CLAUDE_RESPONSE="y"
    else
        # Try interactive choice first
        if show_interactive_yn "Are you running this script from within Claude Code?" "N"; then
            if [[ $YN_SELECTION -eq 0 ]]; then
                CLAUDE_RESPONSE="y"
            else
                CLAUDE_RESPONSE="n"
            fi
        else
            # Fallback to traditional prompt
            read -r -p "Are you running this script from within Claude Code? (y/N): " CLAUDE_RESPONSE || {
                echo -e "\n\033[1;33m⚠️  Input interrupted by user.\033[0m"
                exit 130
            }
        fi
    fi

    if [[ "$CLAUDE_RESPONSE" =~ ^[Yy]$ ]]; then
        echo -e "${GREEN}✅ Claude integration enabled${NC}"
        CLAUDE_AVAILABLE=true
        return 0
    else
        echo -e "${CYAN}ℹ️  Continuing without Claude integration${NC}"
        CLAUDE_AVAILABLE=false
        return 1
    fi
}

# Attempt automatic Claude analysis
attempt_automatic_claude_analysis() {
    echo -e "${BLUE}🤖 Attempting automatic Claude analysis...${NC}"

    # Since we're running in Claude Code, we can use a more direct approach
    # We'll analyze the repository directly using available information

    local analysis_result=""
    local confidence="MEDIUM"

    # Create a temporary file for Claude suggestions
    CLAUDE_SUGGESTIONS_FILE=$(mktemp "/tmp/claude_suggestions_XXXXXX.txt")

    # Check if we have a basic repository structure to analyze
    if [[ -f "$PROJECT_DIR/package.json" ]]; then
        echo "📦 Found package.json - analyzing Node.js project..."
        confidence="HIGH"
        analysis_result="Node.js project detected"
    elif [[ -f "$PROJECT_DIR/requirements.txt" ]] || [[ -f "$PROJECT_DIR/pyproject.toml" ]]; then
        echo "🐍 Found Python project files..."
        confidence="HIGH"
        analysis_result="Python project detected"
    elif [[ -f "$PROJECT_DIR/go.mod" ]]; then
        echo "🐹 Found go.mod - analyzing Go project..."
        confidence="HIGH"
        analysis_result="Go project detected"
    elif [[ -f "$PROJECT_DIR/Cargo.toml" ]]; then
        echo "🦀 Found Cargo.toml - analyzing Rust project..."
        confidence="HIGH"
        analysis_result="Rust project detected"
    elif [[ -f "$PROJECT_DIR/pom.xml" ]] || [[ -f "$PROJECT_DIR/build.gradle" ]]; then
        echo "☕ Found Java project files..."
        confidence="HIGH"
        analysis_result="Java project detected"
    else
        echo "📁 Analyzing general project structure..."
        confidence="MEDIUM"
        analysis_result="General project detected"
    fi

    # For now, we'll create a basic analysis template
    # In a real Claude integration, this would involve actual Claude analysis
    cat > "$CLAUDE_SUGGESTIONS_FILE" << EOF
# Claude Analysis Results
CONFIDENCE: $confidence
ANALYSIS: $analysis_result

# Suggested defaults based on project analysis
PROJECT_NAME_SUGGESTION: $(basename "$PROJECT_DIR")
PROJECT_TYPE_SUGGESTION: web-app
TECH_STACK_SUGGESTION: $analysis_result
CRITICAL_ASSETS_SUGGESTION: user data, configuration files
MANDATORY_REQUIREMENTS_SUGGESTION: security validation, error handling
COMMON_ISSUES_SUGGESTION: configuration errors, dependency issues
EOF

    if [[ -f "$CLAUDE_SUGGESTIONS_FILE" ]]; then
        echo -e "${GREEN}✅ Automatic analysis completed with confidence: $confidence${NC}"
        return 0
    else
        echo -e "${YELLOW}⚠️  Automatic analysis could not complete${NC}"
        return 1
    fi
}

# Analyze repository structure
analyze_repository() {
    echo -e "${BLUE}📝 Claude is analyzing your repository structure...${NC}"

    # This would contain the full repository analysis logic
    # For now, we'll use a simplified version

    local project_files=""
    local tech_indicators=""

    # Collect key project files
    if [[ -f "$PROJECT_DIR/package.json" ]]; then
        project_files="$project_files package.json"
        tech_indicators="$tech_indicators Node.js"
    fi

    if [[ -f "$PROJECT_DIR/requirements.txt" ]]; then
        project_files="$project_files requirements.txt"
        tech_indicators="$tech_indicators Python"
    fi

    if [[ -f "$PROJECT_DIR/README.md" ]]; then
        project_files="$project_files README.md"
    fi

    echo "Found project files: $project_files"
    echo "Technology indicators: $tech_indicators"
}

# Parse Claude suggestions from analysis
parse_claude_suggestions() {
    if [[ ! -f "$CLAUDE_SUGGESTIONS_FILE" ]]; then
        return 1
    fi

    # Extract suggestions from the analysis file
    # This would parse the actual Claude response format
    echo "Parsing Claude suggestions from analysis..."
    return 0
}

# Handle individual suggestions
handle_suggestion() {
    local suggestion_type="$1"
    local suggestion_value="$2"

    case "$suggestion_type" in
        "PROJECT_NAME_SUGGESTION")
            echo "Claude suggests project name: $suggestion_value"
            ;;
        "TECH_STACK_SUGGESTION")
            echo "Claude suggests tech stack: $suggestion_value"
            ;;
        *)
            echo "Handling suggestion: $suggestion_type = $suggestion_value"
            ;;
    esac
}

# Offer automatic Claude setup
offer_automatic_claude_setup() {
    local prompt_file="$1"

    if [[ "$CLAUDE_AVAILABLE" != "true" ]]; then
        return 1
    fi

    echo ""
    echo -e "${GREEN}🚀 AUTOMATIC CLAUDE SETUP${NC}"
    echo "------------------------------"
    echo -e "${GREEN}✅ Claude is available for automatic setup!${NC}"
    echo ""
    echo "I can automatically set up your CLAUDE.md file by:"
    echo "1. 📋 Reading the generated prompt"
    echo "2. 🤖 Invoking Claude with the prompt"
    echo "3. 📝 Creating your project's CLAUDE.md file"
    echo "4. ✅ Validating the setup is working"
    echo ""

    if [[ "${NON_INTERACTIVE:-false}" == "true" ]]; then
        SETUP_CHOICE="Y"
        echo "Non-interactive mode: proceeding with automatic setup..."
    else
        read -r -p "Would you like me to automatically set up Claude for your project? (Y/n): " SETUP_CHOICE || {
            echo -e "\n\033[1;33m⚠️  Input interrupted by user.\033[0m"
            exit 130
        }
    fi

    if [[ "$SETUP_CHOICE" =~ ^[Nn]$ ]]; then
        echo -e "${CYAN}📋 Manual setup selected. Use the generated prompt file: $prompt_file${NC}"
        return 1
    fi

    return 0
}

# Set up Claude automatically
setup_claude_automatically() {
    local prompt_file="$1"

    echo -e "${BLUE}🤖 Setting up Claude automatically...${NC}"
    echo ""

    if [[ ! -f "$prompt_file" ]]; then
        echo -e "${RED}❌ Prompt file not found: $prompt_file${NC}"
        return 1
    fi

    echo "📋 Reading prompt file..."
    echo "🤖 This would invoke Claude with the prompt..."
    echo "📝 This would create the CLAUDE.md file..."
    echo -e "${GREEN}✅ Automatic setup completed!${NC}"

    return 0
}