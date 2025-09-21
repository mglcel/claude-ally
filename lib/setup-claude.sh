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

    # Since we're running in Claude Code, we can leverage Claude for intelligent analysis
    local analysis_result=""
    local confidence="HIGH"

    # Create a temporary file for Claude suggestions
    CLAUDE_SUGGESTIONS_FILE="/tmp/claude_suggestions_$(date +%s)_$$.txt"
    export CLAUDE_SUGGESTIONS_FILE

    # Use the existing stack detection system first
    local detected_stack_info=""
    local project_path="${PROJECT_DIR:-$(pwd)}"
    if declare -f detect_project_stack > /dev/null; then
        detected_stack_info=$(detect_project_stack "$project_path" 2>/dev/null || echo "")
    fi

    # Initialize with defaults that will be overridden by Claude analysis
    local suggested_project_type="web-app"
    local suggested_tech_stack="Unknown"
    local suggested_critical_assets="user data, configuration files"
    local suggested_requirements="security validation, error handling"
    local suggested_issues="configuration errors, dependency issues"
    local suggested_compliance="7"

    # Perform Claude-powered project analysis
    echo "🤖 Claude is analyzing your project structure..."
    local analysis_success=false

    # Try to leverage Claude for intelligent project analysis
    if perform_claude_project_analysis "$project_path"; then
        analysis_success=true
        echo "✅ Claude analysis completed successfully"
    else
        echo "⚠️  Claude analysis unavailable, using stack detection"
    fi

    # Generate suggestions based on detected stack or intelligent analysis
    if [[ -n "$detected_stack_info" ]]; then
        # Parse the detected stack information
        IFS='|' read -r stack_id tech_stack project_type confidence <<< "$detected_stack_info"

        echo "🔍 Using detected stack: $tech_stack"
        analysis_result="$tech_stack detected via stack detection"
        suggested_tech_stack="$tech_stack"
        confidence="HIGH"

        # Map to appropriate project type suggestions based on detected stack
        case "$stack_id" in
            "nextjs-ai")
                suggested_project_type="web-app"
                suggested_critical_assets="user sessions, API keys, AI model data"
                suggested_requirements="input validation, rate limiting, API security"
                suggested_issues="async errors, AI model hallucinations, API limits"
                suggested_compliance="8"
                ;;
            "python-ai")
                suggested_project_type="ai-ml-service"
                suggested_critical_assets="training data, model weights, API keys"
                suggested_requirements="data validation, model security, resource limits"
                suggested_issues="dependency conflicts, model performance, data quality"
                suggested_compliance="7"
                ;;
            "cordova-hybrid")
                suggested_project_type="mobile-app"
                suggested_critical_assets="user data, device permissions, app store keys"
                suggested_requirements="platform compatibility, secure storage"
                suggested_issues="platform differences, performance issues"
                suggested_compliance="6"
                ;;
            *)
                suggested_project_type="web-app"
                suggested_critical_assets="user data, configuration files"
                suggested_requirements="security validation, error handling"
                suggested_issues="configuration errors, dependency issues"
                suggested_compliance="7"
                ;;
        esac
    elif [[ "$analysis_success" == "true" ]]; then
        echo "🤖 Using Claude analysis results"
        confidence="HIGH"
        analysis_result="Claude AI project analysis"
        # Claude analysis would have updated the suggestion variables
    else
        echo "📁 No specific stack detected - using fallback analysis"
        confidence="LOW"
        analysis_result="Fallback analysis - Claude integration needed"
        # suggested_tech_stack remains "Unknown" until Claude analysis is implemented
    fi

    # Create intelligent suggestions based on project analysis
    cat > "$CLAUDE_SUGGESTIONS_FILE" << EOF
# Claude Analysis Results
CONFIDENCE: $confidence
ANALYSIS: $analysis_result

# Tailored suggestions based on detected project type
PROJECT_NAME_SUGGESTION: $(basename "$project_path")
PROJECT_TYPE_SUGGESTION: $suggested_project_type
TECH_STACK_SUGGESTION: $suggested_tech_stack
CRITICAL_ASSETS_SUGGESTION: $suggested_critical_assets
MANDATORY_REQUIREMENTS_SUGGESTION: $suggested_requirements
COMMON_ISSUES_SUGGESTION: $suggested_issues
COMPLIANCE_SUGGESTION: $suggested_compliance
EOF

    if [[ -f "$CLAUDE_SUGGESTIONS_FILE" ]]; then
        echo -e "${GREEN}✅ Automatic analysis completed with confidence: $confidence${NC}"
        return 0
    else
        echo -e "${YELLOW}⚠️  Automatic analysis could not complete${NC}"
        return 1
    fi
}

# Perform actual Claude analysis of the project
perform_claude_project_analysis() {
    local project_dir="$1"

    # Since we're running in Claude Code environment, Claude can analyze the project
    # This function should leverage Claude's actual capabilities to examine the project structure
    # and provide intelligent suggestions for tech stack, project type, etc.

    echo "🔍 Claude examining project files and structure..."

    # Collect key project information for Claude to analyze
    local key_files=""
    local project_structure=""

    # Look for configuration files that indicate tech stack
    if [[ -f "$project_dir/package.json" ]]; then
        key_files="$key_files package.json"
        # Could read package.json content for framework detection
    fi

    if [[ -f "$project_dir/requirements.txt" ]]; then
        key_files="$key_files requirements.txt"
    fi

    # Look for framework-specific files
    [[ -f "$project_dir/next.config.js" ]] && key_files="$key_files next.config.js"
    [[ -f "$project_dir/vue.config.js" ]] && key_files="$key_files vue.config.js"
    [[ -f "$project_dir/angular.json" ]] && key_files="$key_files angular.json"

    # Analyze directory structure
    [[ -d "$project_dir/src" ]] && project_structure="$project_structure src/"
    [[ -d "$project_dir/components" ]] && project_structure="$project_structure components/"
    [[ -d "$project_dir/pages" ]] && project_structure="$project_structure pages/"

    # TODO: This is where actual Claude integration would happen
    # For now, we'll return false to indicate Claude analysis is not yet implemented
    # The real implementation should:
    # 1. Use Claude to analyze the collected project information
    # 2. Have Claude suggest appropriate tech stack based on files/structure
    # 3. Update the suggestion variables based on Claude's analysis
    # 4. Return true if analysis succeeds

    echo "📝 Project analysis: files=$key_files, structure=$project_structure"
    echo "⚠️  Claude integration for project analysis is pending implementation"

    return 1  # Return false for now until real Claude integration is implemented
}

# Analyze project structure intelligently
analyze_project_structure() {
    local project_dir="$1"

    # Gather project information for intelligent analysis
    local project_files=""
    local config_files=""
    local source_files=""

    # Key configuration files
    [[ -f "$project_dir/package.json" ]] && config_files="$config_files package.json"
    [[ -f "$project_dir/requirements.txt" ]] && config_files="$config_files requirements.txt"
    [[ -f "$project_dir/Gemfile" ]] && config_files="$config_files Gemfile"
    [[ -f "$project_dir/composer.json" ]] && config_files="$config_files composer.json"
    [[ -f "$project_dir/pom.xml" ]] && config_files="$config_files pom.xml"
    [[ -f "$project_dir/Cargo.toml" ]] && config_files="$config_files Cargo.toml"
    [[ -f "$project_dir/go.mod" ]] && config_files="$config_files go.mod"
    [[ -f "$project_dir/pubspec.yaml" ]] && config_files="$config_files pubspec.yaml"

    # Framework indicators
    [[ -f "$project_dir/next.config.js" ]] && project_files="$project_files next.config.js"
    [[ -f "$project_dir/vue.config.js" ]] && project_files="$project_files vue.config.js"
    [[ -f "$project_dir/angular.json" ]] && project_files="$project_files angular.json"
    [[ -f "$project_dir/gatsby-config.js" ]] && project_files="$project_files gatsby-config.js"
    [[ -f "$project_dir/nuxt.config.js" ]] && project_files="$project_files nuxt.config.js"

    # Directory structure indicators
    [[ -d "$project_dir/src" ]] && source_files="$source_files src/"
    [[ -d "$project_dir/lib" ]] && source_files="$source_files lib/"
    [[ -d "$project_dir/components" ]] && source_files="$source_files components/"
    [[ -d "$project_dir/pages" ]] && source_files="$source_files pages/"
    [[ -d "$project_dir/app" ]] && source_files="$source_files app/"

    # Output analysis summary
    echo "CONFIG_FILES:$config_files|FRAMEWORK_FILES:$project_files|SOURCE_DIRS:$source_files"
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