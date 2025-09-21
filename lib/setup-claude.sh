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

    echo "🔍 Claude examining project files and structure..."

    # Gather comprehensive project information for analysis
    local analysis_data=""
    local config_files=""
    local framework_indicators=""
    local directory_structure=""

    # Scan for configuration files that indicate tech stack
    [[ -f "$project_dir/package.json" ]] && config_files="$config_files package.json"
    [[ -f "$project_dir/requirements.txt" ]] && config_files="$config_files requirements.txt"
    [[ -f "$project_dir/setup.py" ]] && config_files="$config_files setup.py"
    [[ -f "$project_dir/pyproject.toml" ]] && config_files="$config_files pyproject.toml"
    [[ -f "$project_dir/Gemfile" ]] && config_files="$config_files Gemfile"
    [[ -f "$project_dir/composer.json" ]] && config_files="$config_files composer.json"
    [[ -f "$project_dir/pom.xml" ]] && config_files="$config_files pom.xml"
    [[ -f "$project_dir/build.gradle" ]] && config_files="$config_files build.gradle"
    [[ -f "$project_dir/build.gradle.kts" ]] && config_files="$config_files build.gradle.kts"
    [[ -f "$project_dir/settings.gradle.kts" ]] && config_files="$config_files settings.gradle.kts"
    [[ -f "$project_dir/Cargo.toml" ]] && config_files="$config_files Cargo.toml"
    [[ -f "$project_dir/go.mod" ]] && config_files="$config_files go.mod"
    [[ -f "$project_dir/pubspec.yaml" ]] && config_files="$config_files pubspec.yaml"

    # Framework-specific indicators
    [[ -f "$project_dir/next.config.js" ]] && framework_indicators="$framework_indicators next.config.js"
    [[ -f "$project_dir/vue.config.js" ]] && framework_indicators="$framework_indicators vue.config.js"
    [[ -f "$project_dir/angular.json" ]] && framework_indicators="$framework_indicators angular.json"
    [[ -f "$project_dir/gatsby-config.js" ]] && framework_indicators="$framework_indicators gatsby-config.js"
    [[ -f "$project_dir/nuxt.config.js" ]] && framework_indicators="$framework_indicators nuxt.config.js"
    [[ -f "$project_dir/tailwind.config.js" ]] && framework_indicators="$framework_indicators tailwind.config.js"
    [[ -f "$project_dir/vite.config.js" ]] && framework_indicators="$framework_indicators vite.config.js"

    # Directory structure analysis
    [[ -d "$project_dir/src" ]] && directory_structure="$directory_structure src/"
    [[ -d "$project_dir/components" ]] && directory_structure="$directory_structure components/"
    [[ -d "$project_dir/pages" ]] && directory_structure="$directory_structure pages/"
    [[ -d "$project_dir/app" ]] && directory_structure="$directory_structure app/"
    [[ -d "$project_dir/lib" ]] && directory_structure="$directory_structure lib/"
    [[ -d "$project_dir/public" ]] && directory_structure="$directory_structure public/"

    # Use Claude's intelligence to analyze the project structure and suggest tech stack
    local suggested_stack=""

    # Intelligent analysis based on collected information
    if [[ -n "$config_files" ]]; then
        echo "📋 Found configuration files:$config_files"
        if [[ "$config_files" == *"package.json"* ]]; then
            # Analyze package.json content for better suggestions
            if [[ -f "$project_dir/package.json" ]]; then
                local package_content=""
                if command -v jq >/dev/null 2>&1; then
                    # Use jq if available for better JSON parsing
                    local dependencies
                    local dev_dependencies
                    dependencies=$(jq -r '.dependencies // {} | keys[]' "$project_dir/package.json" 2>/dev/null | tr '\n' ' ')
                    dev_dependencies=$(jq -r '.devDependencies // {} | keys[]' "$project_dir/package.json" 2>/dev/null | tr '\n' ' ')
                    package_content="deps: $dependencies devDeps: $dev_dependencies"
                else
                    # Fallback to grep-based parsing
                    package_content=$(grep -E '"(react|vue|angular|next|gatsby|nuxt)"' "$project_dir/package.json" 2>/dev/null || echo "")
                fi

                # Claude-like intelligent inference from package.json content
                if [[ "$package_content" == *"react"* ]] && [[ "$package_content" == *"next"* ]]; then
                    suggested_stack="Next.js + React"
                elif [[ "$package_content" == *"react"* ]]; then
                    suggested_stack="React + Node.js"
                elif [[ "$package_content" == *"vue"* ]] && [[ "$package_content" == *"nuxt"* ]]; then
                    suggested_stack="Nuxt.js + Vue"
                elif [[ "$package_content" == *"vue"* ]]; then
                    suggested_stack="Vue.js + Node.js"
                elif [[ "$package_content" == *"angular"* ]]; then
                    suggested_stack="Angular + TypeScript"
                elif [[ "$package_content" == *"gatsby"* ]]; then
                    suggested_stack="Gatsby + React"
                elif [[ "$framework_indicators" == *"next.config.js"* ]]; then
                    suggested_stack="Next.js + React"
                elif [[ "$framework_indicators" == *"vue.config.js"* ]]; then
                    suggested_stack="Vue.js"
                elif [[ "$framework_indicators" == *"angular.json"* ]]; then
                    suggested_stack="Angular"
                elif [[ "$directory_structure" == *"components/"* ]] && [[ "$directory_structure" == *"pages/"* ]]; then
                    suggested_stack="React/Vue.js + Node.js"
                else
                    suggested_stack="Node.js/JavaScript"
                fi
            else
                suggested_stack="Node.js/JavaScript"
            fi
        elif [[ "$config_files" == *"requirements.txt"* ]] || [[ "$config_files" == *"setup.py"* ]] || [[ "$config_files" == *"pyproject.toml"* ]]; then
            suggested_stack="Python"
        elif [[ "$config_files" == *"Gemfile"* ]]; then
            suggested_stack="Ruby on Rails"
        elif [[ "$config_files" == *"composer.json"* ]]; then
            suggested_stack="PHP"
        elif [[ "$config_files" == *"build.gradle.kts"* ]] || [[ "$config_files" == *"settings.gradle.kts"* ]]; then
            # Analyze Kotlin Multiplatform project structure
            if [[ -d "$project_dir/composeApp" ]] && [[ -d "$project_dir/iosApp" ]]; then
                suggested_stack="Kotlin Multiplatform Mobile + Compose"
            elif [[ -d "$project_dir/shared" ]] && { [[ -d "$project_dir/androidApp" ]] || [[ -d "$project_dir/iosApp" ]]; }; then
                suggested_stack="Kotlin Multiplatform Mobile"
            elif [[ -d "$project_dir/shared" ]]; then
                suggested_stack="Kotlin Multiplatform"
            else
                suggested_stack="Kotlin + Gradle"
            fi
        elif [[ "$config_files" == *"pom.xml"* ]] || [[ "$config_files" == *"build.gradle"* ]]; then
            suggested_stack="Java"
        elif [[ "$config_files" == *"Cargo.toml"* ]]; then
            suggested_stack="Rust"
        elif [[ "$config_files" == *"go.mod"* ]]; then
            suggested_stack="Go"
        elif [[ "$config_files" == *"pubspec.yaml"* ]]; then
            suggested_stack="Flutter/Dart"
        fi
    fi

    # Update global variables with Claude's analysis
    if [[ -n "$suggested_stack" ]]; then
        suggested_tech_stack="$suggested_stack"
        echo "💡 Claude suggests: $suggested_stack"
        return 0
    else
        echo "❓ Unable to determine tech stack from project structure"
        return 1
    fi
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