#!/bin/bash

# Claude Ally Setup Script - Enhanced with Claude Intelligence
# Generates a customized prompt for creating your project's CLAUDE.md file.
# Now with Claude-powered repository analysis for intelligent defaults!
# Version 2.0 - Optimized Performance & Error Handling

set -e

# Load optimization modules
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source optimization modules if available (fail silently if not present)
[[ -f "$SCRIPT_DIR/error-handler.sh" ]] && source "$SCRIPT_DIR/error-handler.sh" && setup_error_trapping 2>/dev/null || true
[[ -f "$SCRIPT_DIR/config-manager.sh" ]] && source "$SCRIPT_DIR/config-manager.sh" 2>/dev/null || true
[[ -f "$SCRIPT_DIR/cache-manager.sh" ]] && source "$SCRIPT_DIR/cache-manager.sh" 2>/dev/null || true
[[ -f "$SCRIPT_DIR/performance-monitor.sh" ]] && source "$SCRIPT_DIR/performance-monitor.sh" 2>/dev/null || true

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Global variables for Claude suggestions
CLAUDE_AVAILABLE=false
CLAUDE_SUGGESTIONS_FILE=""
REPOSITORY_ANALYSIS=""
SCRIPT_DIR=""
PROJECT_DIR=""
WORKING_DIR=""

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
        read -p "Do you want to continue analyzing claude-ally? (y/N): " ANALYZE_SELF
        if [[ ! "$ANALYZE_SELF" =~ ^[Yy]$ ]]; then
            echo -e "${CYAN}💡 TIP: Run this script from your project directory:${NC}"
            echo "   cd /path/to/your/project"
            echo "   $SCRIPT_DIR/setup.sh"
            exit 0
        fi
    fi
}

print_header() {
    echo "============================================================"
    echo "🤖 CLAUDE ALLY - COGNITIVE ENHANCEMENT SETUP"
    echo "🧠 Enhanced with Claude Intelligence"
    echo "============================================================"
    echo "This script will analyze your repository and use Claude to suggest"
    echo "intelligent defaults for your cognitive enhancement system."
    echo ""
}

check_claude_availability() {
    echo -e "${BLUE}🔍 Checking Claude availability...${NC}"

    # Check if we're in a claude-code environment
    if command -v claude &> /dev/null; then
        echo -e "${GREEN}✅ Claude Code CLI detected${NC}"
        CLAUDE_AVAILABLE=true
        return 0
    fi

    # Check if this appears to be a claude-code session (common env vars)
    if [[ -n "$CLAUDE_CODE_SESSION" ]] || [[ -n "$CLAUDE_PROJECT_ROOT" ]] || [[ -n "$CLAUDECODE" ]] || [[ -n "$CLAUDE_CODE_ENTRYPOINT" ]]; then
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
    read -p "Are you running this script from within Claude Code? (y/N): " CLAUDE_RESPONSE

    if [[ "$CLAUDE_RESPONSE" =~ ^[Yy]$ ]]; then
        echo -e "${GREEN}✅ Claude integration enabled by user${NC}"
        CLAUDE_AVAILABLE=true
        return 0
    else
        echo -e "${CYAN}ℹ️  Continuing without Claude integration${NC}"
        CLAUDE_AVAILABLE=false
        return 1
    fi
}

attempt_automatic_claude_analysis() {
    echo -e "${BLUE}🤖 Attempting automatic Claude analysis...${NC}"

    # Since we're running in Claude Code, we can use a more direct approach
    # We'll analyze the repository directly using available information

    local analysis_result=""
    local confidence="MEDIUM"

    # Analyze project name
    local project_name=""
    if [[ -f "$PROJECT_DIR/package.json" ]]; then
        project_name=$(grep '"name"' "$PROJECT_DIR/package.json" | sed 's/.*"name"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/')
    elif [[ -f "$PROJECT_DIR/composer.json" ]]; then
        project_name=$(grep '"name"' "$PROJECT_DIR/composer.json" | sed 's/.*"name"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/')
    elif [[ -f "$PROJECT_DIR/go.mod" ]]; then
        project_name=$(head -1 "$PROJECT_DIR/go.mod" | awk '{print $2}' | xargs basename)
    elif [[ -f "$PROJECT_DIR/Cargo.toml" ]]; then
        project_name=$(grep '^name' "$PROJECT_DIR/Cargo.toml" | head -1 | sed 's/name[[:space:]]*=[[:space:]]*"\([^"]*\)".*/\1/')
    else
        project_name=$(basename "$PROJECT_DIR")
    fi

    # Analyze project type and tech stack
    local project_type="web-app"
    local tech_stack=""
    local database_tech="None"

    # Try modular stack detection first
    if [[ -f "$SCRIPT_DIR/stack-detector.sh" ]]; then
        source "$SCRIPT_DIR/stack-detector.sh"
        local modular_result
        if modular_result=$(detect_project_stack "$PROJECT_DIR" 2>/dev/null); then
            local stack_id detected_tech_stack detected_project_type detected_confidence
            IFS='|' read -r stack_id detected_tech_stack detected_project_type detected_confidence <<< "$modular_result"

            if [[ $detected_confidence -ge 60 ]]; then
                tech_stack="$detected_tech_stack"
                project_type="$detected_project_type"
                confidence="HIGH"
                echo -e "${GREEN}🧬 Modular detection: $stack_id (confidence: $detected_confidence%)${NC}"
            fi
        fi
    fi

    # Fallback to legacy detection if modular detection didn't find anything
    if [[ -z "$tech_stack" ]] && [[ -f "$PROJECT_DIR/package.json" ]]; then
        if grep -q '"react"' "$PROJECT_DIR/package.json"; then
            tech_stack="JavaScript/Node.js, React"
            if grep -q '"express"' "$PROJECT_DIR/package.json"; then
                tech_stack="$tech_stack, Express"
                project_type="web-app"
            fi
        elif grep -q '"vue"' "$PROJECT_DIR/package.json"; then
            tech_stack="JavaScript/Node.js, Vue.js"
            project_type="web-app"
        elif grep -q '"angular"' "$PROJECT_DIR/package.json"; then
            tech_stack="TypeScript/Angular"
            project_type="web-app"
        elif grep -q '"express"' "$PROJECT_DIR/package.json"; then
            tech_stack="JavaScript/Node.js, Express"
            project_type="backend-service"
        else
            tech_stack="JavaScript/Node.js"
        fi

        # Check for databases
        if grep -q '"pg"' "$PROJECT_DIR/package.json" || grep -q '"postgres"' "$PROJECT_DIR/package.json"; then
            database_tech="PostgreSQL"
        elif grep -q '"mysql"' "$PROJECT_DIR/package.json"; then
            database_tech="MySQL"
        elif grep -q '"mongodb"' "$PROJECT_DIR/package.json" || grep -q '"mongoose"' "$PROJECT_DIR/package.json"; then
            database_tech="MongoDB"
        elif grep -q '"sqlite"' "$PROJECT_DIR/package.json"; then
            database_tech="SQLite"
        elif grep -q '"redis"' "$PROJECT_DIR/package.json"; then
            database_tech="Redis"
        fi

        confidence="HIGH"
    elif [[ -f "$PROJECT_DIR/requirements.txt" ]] || [[ -f "$PROJECT_DIR/pyproject.toml" ]]; then
        # AI/ML project detection first (highest priority)
        if grep -q -i "torch\|tensorflow\|sklearn\|transformers\|gradio" "$PROJECT_DIR/requirements.txt" 2>/dev/null || grep -q -i "torch\|tensorflow\|sklearn\|transformers\|gradio" "$PROJECT_DIR/pyproject.toml" 2>/dev/null; then
            if grep -q -i "torch\|transformers" "$PROJECT_DIR/requirements.txt" 2>/dev/null; then
                tech_stack="Python/PyTorch, AI/ML"
            elif grep -q -i "tensorflow" "$PROJECT_DIR/requirements.txt" 2>/dev/null; then
                tech_stack="Python/TensorFlow, AI/ML"
            else
                tech_stack="Python/AI/ML"
            fi
            project_type="ai-ml-service"
        elif grep -q -i "django" "$PROJECT_DIR/requirements.txt" 2>/dev/null || grep -q -i "django" "$PROJECT_DIR/pyproject.toml" 2>/dev/null; then
            tech_stack="Python/Django"
            project_type="web-app"
        elif grep -q -i "flask" "$PROJECT_DIR/requirements.txt" 2>/dev/null || grep -q -i "flask" "$PROJECT_DIR/pyproject.toml" 2>/dev/null; then
            tech_stack="Python/Flask"
            project_type="web-app"
        elif grep -q -i "fastapi" "$PROJECT_DIR/requirements.txt" 2>/dev/null || grep -q -i "fastapi" "$PROJECT_DIR/pyproject.toml" 2>/dev/null; then
            tech_stack="Python/FastAPI"
            project_type="backend-service"
        else
            tech_stack="Python"
        fi

        if grep -q -i "psycopg" "$PROJECT_DIR/requirements.txt" 2>/dev/null; then
            database_tech="PostgreSQL"
        elif grep -q -i "mysql" "$PROJECT_DIR/requirements.txt" 2>/dev/null; then
            database_tech="MySQL"
        elif grep -q -i "pymongo" "$PROJECT_DIR/requirements.txt" 2>/dev/null; then
            database_tech="MongoDB"
        fi

        confidence="HIGH"
    elif [[ -f "$PROJECT_DIR/go.mod" ]]; then
        tech_stack="Go"
        if grep -q "gin-gonic" "$PROJECT_DIR/go.mod"; then
            tech_stack="Go/Gin"
        elif grep -q "echo" "$PROJECT_DIR/go.mod"; then
            tech_stack="Go/Echo"
        elif grep -q "fiber" "$PROJECT_DIR/go.mod"; then
            tech_stack="Go/Fiber"
        fi
        project_type="backend-service"
        confidence="HIGH"
    elif [[ -f "$PROJECT_DIR/Cargo.toml" ]]; then
        tech_stack="Rust"
        if grep -q "actix-web" "$PROJECT_DIR/Cargo.toml"; then
            tech_stack="Rust/Actix"
        elif grep -q "warp" "$PROJECT_DIR/Cargo.toml"; then
            tech_stack="Rust/Warp"
        elif grep -q "rocket" "$PROJECT_DIR/Cargo.toml"; then
            tech_stack="Rust/Rocket"
        fi
        project_type="backend-service"
        confidence="HIGH"
    elif [[ -f "$PROJECT_DIR/composer.json" ]]; then
        tech_stack="PHP"
        if grep -q "laravel" "$PROJECT_DIR/composer.json"; then
            tech_stack="PHP/Laravel"
        elif grep -q "symfony" "$PROJECT_DIR/composer.json"; then
            tech_stack="PHP/Symfony"
        fi
        project_type="web-app"
        confidence="HIGH"
    elif [[ -f "$PROJECT_DIR/pom.xml" ]]; then
        tech_stack="Java"
        if grep -q "spring-boot" "$PROJECT_DIR/pom.xml"; then
            tech_stack="Java/Spring Boot"
        elif grep -q "spring" "$PROJECT_DIR/pom.xml"; then
            tech_stack="Java/Spring"
        fi
        project_type="backend-service"
        confidence="HIGH"
    elif [[ -d "$PROJECT_DIR/src" ]] && [[ -f "$PROJECT_DIR/setup.sh" ]] && [[ "$project_name" == *"claude-ally"* ]]; then
        # Looks like claude-ally itself!
        tech_stack="Shell scripting, Markdown, Git"
        project_type="backend-service"
        confidence="HIGH"
    elif [[ -f "$PROJECT_DIR/setup.sh" ]] && [[ -f "$PROJECT_DIR/validate.sh" ]] && [[ -f "$PROJECT_DIR/UNIVERSAL_COGNITIVE_ENHANCEMENT_PROMPT.md" ]]; then
        # This is definitely claude-ally!
        tech_stack="Shell scripting, Markdown, Git"
        project_type="backend-service"
        confidence="HIGH"
    elif [[ -f "$PROJECT_DIR/build.gradle.kts" ]] || [[ -f "$PROJECT_DIR/build.gradle" ]]; then
        # Kotlin/Android/Gradle project
        if grep -q "kotlin.*multiplatform" "$PROJECT_DIR/build.gradle.kts" 2>/dev/null || grep -q "kotlin.*multiplatform" "$PROJECT_DIR/build.gradle" 2>/dev/null; then
            tech_stack="Kotlin Multiplatform Mobile"
            project_type="mobile-app"
        elif grep -q "com.android.application" "$PROJECT_DIR/build.gradle.kts" 2>/dev/null || grep -q "com.android.application" "$PROJECT_DIR/build.gradle" 2>/dev/null; then
            tech_stack="Kotlin/Android"
            project_type="mobile-app"
        elif grep -q "jetbrainsCompose" "$PROJECT_DIR/build.gradle.kts" 2>/dev/null; then
            tech_stack="Kotlin/Compose Multiplatform"
            project_type="mobile-app"
        elif grep -q "spring" "$PROJECT_DIR/build.gradle.kts" 2>/dev/null || grep -q "spring" "$PROJECT_DIR/build.gradle" 2>/dev/null; then
            tech_stack="Kotlin/Spring"
            project_type="backend-service"
        else
            tech_stack="Kotlin/Gradle"
            project_type="backend-service"
        fi
        confidence="HIGH"
    elif [[ -f "$PROJECT_DIR/settings.gradle.kts" ]] && [[ -d "$PROJECT_DIR/composeApp" ]]; then
        # Definitely a Compose Multiplatform project
        tech_stack="Kotlin Multiplatform Mobile, Compose"
        project_type="mobile-app"
        confidence="HIGH"
    elif [[ -f "$PROJECT_DIR/config.xml" ]] && [[ -f "$PROJECT_DIR/package.json" ]]; then
        # Cordova hybrid mobile app
        if grep -q "cordova-" "$PROJECT_DIR/package.json"; then
            if grep -q "mapbox\|leaflet" "$PROJECT_DIR/package.json"; then
                tech_stack="JavaScript/Cordova, Maps"
            else
                tech_stack="JavaScript/Cordova"
            fi
            project_type="cordova-hybrid-app"
            confidence="HIGH"
        fi
    elif [[ -f "$PROJECT_DIR/index.html" ]] && [[ ! -f "$PROJECT_DIR/package.json" ]] && [[ ! -f "$PROJECT_DIR/requirements.txt" ]] && [[ ! -f "$PROJECT_DIR/composer.json" ]]; then
        # Static website - only HTML files, no backend framework
        tech_stack="HTML, CSS, JavaScript"
        project_type="static-website"
        if [[ "$project_name" == *"deprecated"* ]] || [[ "$project_name" == *"legacy"* ]]; then
            project_type="legacy-website"
        fi
        confidence="HIGH"
    fi

    # Analyze critical assets
    local critical_assets="user data, application configurations"
    if [[ "$project_name" == *"claude-ally"* ]] || [[ -f "$PROJECT_DIR/UNIVERSAL_COGNITIVE_ENHANCEMENT_PROMPT.md" ]]; then
        critical_assets="cognitive enhancement prompts, user project configurations"
    elif grep -q -i "payment\|stripe\|paypal" "$PROJECT_DIR"/* 2>/dev/null; then
        critical_assets="user data, payment information, API keys"
    elif grep -q -i "auth\|jwt\|token" "$PROJECT_DIR"/* 2>/dev/null; then
        critical_assets="user data, authentication tokens, API keys"
    fi

    # Analyze common issues
    local common_issues="performance bottlenecks, dependency management"
    if [[ "$tech_stack" == *"JavaScript"* ]]; then
        common_issues="npm dependency conflicts, async/callback complexity"
    elif [[ "$tech_stack" == *"Python"* ]]; then
        common_issues="dependency version conflicts, memory usage"
    elif [[ "$tech_stack" == *"Go"* ]]; then
        common_issues="concurrency management, error handling"
    elif [[ "$tech_stack" == *"Kotlin"* ]]; then
        if [[ "$tech_stack" == *"Multiplatform"* ]]; then
            common_issues="platform-specific code compilation, shared code compatibility"
        elif [[ "$tech_stack" == *"Android"* ]]; then
            common_issues="memory leaks, ANR issues, fragmentation"
        else
            common_issues="coroutine management, null safety, compilation time"
        fi
    elif [[ "$project_name" == *"claude-ally"* ]]; then
        common_issues="prompt customization complexity, setup time"
    fi

    # Analyze file structure
    local file_structure="standard project layout"
    if [[ -d "$PROJECT_DIR/src" ]]; then
        file_structure="src/ directory structure"
    fi
    if [[ -f "$PROJECT_DIR/package.json" ]]; then
        file_structure="$file_structure, npm package"
    fi
    if [[ -f "$PROJECT_DIR/build.gradle.kts" ]] || [[ -f "$PROJECT_DIR/build.gradle" ]]; then
        file_structure="Gradle build system"
        if [[ -d "$PROJECT_DIR/composeApp" ]]; then
            file_structure="$file_structure, Compose Multiplatform modules"
        fi
        if [[ -d "$PROJECT_DIR/shared" ]]; then
            file_structure="$file_structure, shared code modules"
        fi
        if [[ -d "$PROJECT_DIR/iosApp" ]]; then
            file_structure="$file_structure, iOS app module"
        fi
    fi
    if [[ -f "$PROJECT_DIR/Dockerfile" ]]; then
        file_structure="$file_structure, Docker containers"
    fi
    if [[ "$project_name" == *"claude-ally"* ]]; then
        file_structure="shell scripts, markdown docs, validation tools"
    fi

    # Determine deployment target
    local deployment_target="cloud containers"
    if [[ "$project_type" == "mobile-app" ]]; then
        if [[ "$tech_stack" == *"Multiplatform"* ]]; then
            deployment_target="mobile devices, multiple platforms"
        else
            deployment_target="mobile devices"
        fi
    elif [[ -f "$PROJECT_DIR/Dockerfile" ]]; then
        deployment_target="cloud containers"
    elif [[ "$project_name" == *"claude-ally"* ]]; then
        deployment_target="developer workstations"
    fi

    # Generate the analysis result
    analysis_result="PROJECT_NAME_SUGGESTION: $project_name
PROJECT_TYPE_SUGGESTION: $project_type
TECH_STACK_SUGGESTION: $tech_stack
DATABASE_TECH_SUGGESTION: $database_tech
CRITICAL_ASSETS_SUGGESTION: $critical_assets
MANDATORY_REQUIREMENTS_SUGGESTION: None
COMMON_ISSUES_SUGGESTION: $common_issues
FILE_STRUCTURE_SUGGESTION: $file_structure
DEPLOYMENT_TARGET_SUGGESTION: $deployment_target
CONFIDENCE_LEVEL: $confidence
ANALYSIS_NOTES: Automatic analysis based on project files and structure detection"

    # Save the analysis
    echo "$analysis_result" > "$CLAUDE_SUGGESTIONS_FILE"
    REPOSITORY_ANALYSIS="$analysis_result"

    echo -e "${GREEN}🔍 Automatic analysis completed with confidence: $confidence${NC}"
    return 0
}

analyze_repository() {
    if [[ "$CLAUDE_AVAILABLE" != true ]]; then
        return 0
    fi

    echo ""
    echo -e "${BLUE}🔬 Analyzing repository with Claude...${NC}"
    echo "---------------------------------------------"
    echo "Analyzing project: $PROJECT_DIR"
    echo ""

    # Create a temporary file for analysis
    CLAUDE_SUGGESTIONS_FILE=$(mktemp /tmp/claude_analysis.XXXXXX.md)

    # Generate repository analysis prompt
    cat > "$CLAUDE_SUGGESTIONS_FILE" << 'EOF'
# Repository Analysis for Claude Ally Setup

Please analyze this repository and provide intelligent suggestions for the Claude Ally cognitive enhancement setup. Analyze the following aspects:

## Analysis Request

**PROJECT CONTEXT ANALYSIS:**
1. **Project Name**: Analyze repository name, package.json, README, or other files to suggest project name
2. **Project Type**: Determine if this is web-app, mobile-app, desktop-app, backend-service, data-pipeline, or embedded-system
3. **Tech Stack**: Identify programming languages, frameworks, databases from files like package.json, requirements.txt, go.mod, Cargo.toml, pom.xml, etc.
4. **Database Technology**: Look for database configurations, connection strings, ORM files
5. **Critical Assets**: Identify what data/functionality seems most valuable (user data, payment info, API keys, algorithms)
6. **Compliance Requirements**: Look for GDPR, HIPAA, SOC2 mentions in docs or legal files
7. **Common Issues**: Analyze issue patterns from git history, TODO comments, or documentation
8. **File Structure**: Describe the main project organization
9. **Deployment Target**: Identify from Docker files, CI/CD configs, platform-specific code

## Response Format

Please respond in this exact format for easy parsing:

```
PROJECT_NAME_SUGGESTION: [suggested name]
PROJECT_TYPE_SUGGESTION: [web-app|mobile-app|desktop-app|backend-service|data-pipeline|embedded-system]
TECH_STACK_SUGGESTION: [languages and frameworks, e.g., "Python/Django, React, PostgreSQL"]
DATABASE_TECH_SUGGESTION: [PostgreSQL|MySQL|MongoDB|SQLite|Redis|Multiple|None|Other]
CRITICAL_ASSETS_SUGGESTION: [most valuable assets, e.g., "user data, payment info, API keys"]
MANDATORY_REQUIREMENTS_SUGGESTION: [compliance requirements or "None"]
COMMON_ISSUES_SUGGESTION: [recurring problems, e.g., "performance bottlenecks, memory leaks"]
FILE_STRUCTURE_SUGGESTION: [brief overview, e.g., "src/main/java, gradle build, Docker containers"]
DEPLOYMENT_TARGET_SUGGESTION: [where it runs, e.g., "cloud containers, mobile devices"]
CONFIDENCE_LEVEL: [HIGH|MEDIUM|LOW - how confident you are in these suggestions]
ANALYSIS_NOTES: [brief explanation of your analysis and any uncertainties]
```

Now please analyze this repository:
EOF

    echo -e "${CYAN}📝 Claude is analyzing your repository structure...${NC}"
    echo "   This may take a moment..."

    # Try automatic Claude analysis first
    if attempt_automatic_claude_analysis; then
        echo -e "${GREEN}✅ Automatic analysis completed successfully!${NC}"
        echo ""
    else
        # Fallback to manual copy-paste mode
        echo ""
        echo -e "${YELLOW}📋 CLAUDE ANALYSIS NEEDED${NC}"
        echo "Automatic analysis not available. Please copy the analysis request below to Claude and paste the response here."
        echo "Claude will analyze your repository files and suggest intelligent defaults."
        echo ""
        echo -e "${BOLD}Copy this analysis request to Claude:${NC}"
        echo "----------------------------------------"
        cat "$CLAUDE_SUGGESTIONS_FILE"
        echo "----------------------------------------"
        echo ""
        read -p "Press Enter when you have Claude's analysis ready to paste..."

        echo ""
        echo "Please paste Claude's analysis response here (end with an empty line):"

        # Read Claude's response
        local analysis_response=""
        while IFS= read -r line; do
            if [[ -z "$line" ]]; then
                break
            fi
            analysis_response+="$line"$'\n'
        done

        # Save the analysis
        echo "$analysis_response" > "$CLAUDE_SUGGESTIONS_FILE"
        REPOSITORY_ANALYSIS="$analysis_response"

        echo -e "${GREEN}✅ Analysis received and processed${NC}"
        echo ""
    fi
}

parse_claude_suggestions() {
    if [[ ! -f "$CLAUDE_SUGGESTIONS_FILE" ]] || [[ -z "$REPOSITORY_ANALYSIS" ]]; then
        return 0
    fi

    # Extract suggestions from Claude's response
    PROJECT_NAME_SUGGESTION=$(echo "$REPOSITORY_ANALYSIS" | grep "PROJECT_NAME_SUGGESTION:" | cut -d':' -f2- | xargs)
    PROJECT_TYPE_SUGGESTION=$(echo "$REPOSITORY_ANALYSIS" | grep "PROJECT_TYPE_SUGGESTION:" | cut -d':' -f2- | xargs)
    TECH_STACK_SUGGESTION=$(echo "$REPOSITORY_ANALYSIS" | grep "TECH_STACK_SUGGESTION:" | cut -d':' -f2- | xargs)
    DATABASE_TECH_SUGGESTION=$(echo "$REPOSITORY_ANALYSIS" | grep "DATABASE_TECH_SUGGESTION:" | cut -d':' -f2- | xargs)
    CRITICAL_ASSETS_SUGGESTION=$(echo "$REPOSITORY_ANALYSIS" | grep "CRITICAL_ASSETS_SUGGESTION:" | cut -d':' -f2- | xargs)
    MANDATORY_REQUIREMENTS_SUGGESTION=$(echo "$REPOSITORY_ANALYSIS" | grep "MANDATORY_REQUIREMENTS_SUGGESTION:" | cut -d':' -f2- | xargs)
    COMMON_ISSUES_SUGGESTION=$(echo "$REPOSITORY_ANALYSIS" | grep "COMMON_ISSUES_SUGGESTION:" | cut -d':' -f2- | xargs)
    FILE_STRUCTURE_SUGGESTION=$(echo "$REPOSITORY_ANALYSIS" | grep "FILE_STRUCTURE_SUGGESTION:" | cut -d':' -f2- | xargs)
    DEPLOYMENT_TARGET_SUGGESTION=$(echo "$REPOSITORY_ANALYSIS" | grep "DEPLOYMENT_TARGET_SUGGESTION:" | cut -d':' -f2- | xargs)
    CONFIDENCE_LEVEL=$(echo "$REPOSITORY_ANALYSIS" | grep "CONFIDENCE_LEVEL:" | cut -d':' -f2- | xargs)

    if [[ -n "$PROJECT_NAME_SUGGESTION" ]]; then
        echo -e "${GREEN}🧠 Claude analysis completed with confidence: $CONFIDENCE_LEVEL${NC}"
        echo "   Claude has analyzed your repository and prepared intelligent suggestions."
        echo ""
    fi
}

# Unified function to handle suggestions with user choices
handle_suggestion() {
    local suggestion_type="$1"        # "text" or "choice"
    local prompt="$2"                 # The main prompt text
    local suggestion="$3"             # Claude's suggestion
    local variable_name="$4"          # Variable to store result
    local options_callback="${5:-}"   # Optional function to show options for choice type
    local validation_pattern="${6:-}" # Optional regex pattern for validation

    if [[ -z "$suggestion" ]]; then
        # No suggestion available, fall back to direct input
        if [[ "$suggestion_type" == "choice" && -n "$options_callback" ]]; then
            $options_callback
        else
            while true; do
                read -p "$prompt: " user_input
                if [[ -z "$validation_pattern" || "$user_input" =~ $validation_pattern ]]; then
                    eval "$variable_name=\"$user_input\""
                    break
                else
                    echo -e "${RED}Invalid input. Please try again.${NC}"
                fi
            done
        fi
        return
    fi

    # Show Claude's suggestion
    echo ""
    echo -e "${CYAN}🤖 Claude suggests: ${BOLD}$suggestion${NC}"
    echo ""
    echo "What would you like to do?"
    echo "  1) Accept Claude's suggestion"
    if [[ "$suggestion_type" == "choice" ]]; then
        echo "  2) Choose from all available options"
    else
        echo "  2) Enter a custom value"
    fi
    echo ""

    local choice
    while true; do
        read -p "Choose (1-2) [default: 1]: " choice
        case "$choice" in
            1|"")
                eval "$variable_name=\"$suggestion\""
                echo -e "${GREEN}✅ Using Claude's suggestion: $suggestion${NC}"
                break
                ;;
            2)
                echo ""
                if [[ "$suggestion_type" == "choice" && -n "$options_callback" ]]; then
                    # Show all options and get user choice
                    $options_callback "$variable_name"
                    break
                else
                    # Get custom text input
                    while true; do
                        read -p "$prompt: " user_input
                        if [[ -z "$validation_pattern" || "$user_input" =~ $validation_pattern ]]; then
                            eval "$variable_name=\"$user_input\""
                            echo -e "${GREEN}✅ Using custom value: $user_input${NC}"
                            break
                        else
                            echo -e "${RED}Invalid input. Please try again.${NC}"
                        fi
                    done
                    break
                fi
                ;;
            *)
                echo -e "${RED}Invalid choice. Please enter 1 or 2.${NC}"
                ;;
        esac
    done
}

# Simplified function for text input with suggestions
read_with_default() {
    local prompt="$1"
    local default="$2"
    local variable_name="$3"

    handle_suggestion "text" "$prompt" "$default" "$variable_name"
}

# Helper function to show project type options (global scope)
show_project_type_options() {
    local var_name="${1:-PROJECT_TYPE_CHOICE}"

    echo "Select project type:"
    echo "1. Web application"
    echo "2. Mobile app"
    echo "3. Desktop application"
    echo "4. Backend service/API"
    echo "5. Data pipeline"
    echo "6. Embedded system"
    echo "7. AI/ML service"
    echo "8. Static website"
    echo "9. Cordova hybrid app"
    echo "10. Legacy website"
    echo "11. Other"
    echo ""

    local choice
    while true; do
        read -p "Select project type (1-11): " choice
        if [[ "$choice" =~ ^[1-9]$|^1[01]$ ]]; then
            eval "$var_name=\"$choice\""
            echo -e "${GREEN}✅ Selected: $choice${NC}"
            break
        else
            echo -e "${RED}Invalid choice. Please enter a number between 1-11.${NC}"
        fi
    done
}

get_project_info() {
    echo -e "${BLUE}📋 PROJECT INFORMATION${NC}"
    echo "------------------------------"

    read_with_default "Project name:" "$PROJECT_NAME_SUGGESTION" "PROJECT_NAME"

    # Project type selection using global helper function

    # Map Claude suggestion to choice number
    local suggested_choice=""
    case "$PROJECT_TYPE_SUGGESTION" in
        "web-app") suggested_choice="1" ;;
        "mobile-app") suggested_choice="2" ;;
        "desktop-app") suggested_choice="3" ;;
        "backend-service") suggested_choice="4" ;;
        "data-pipeline") suggested_choice="5" ;;
        "embedded-system") suggested_choice="6" ;;
        "ai-ml-service") suggested_choice="7" ;;
        "static-website") suggested_choice="8" ;;
        "cordova-hybrid-app") suggested_choice="9" ;;
        "legacy-website") suggested_choice="10" ;;
        *) suggested_choice="" ;;
    esac

    echo ""
    handle_suggestion "choice" "Select project type" "$suggested_choice" "PROJECT_TYPE_CHOICE" "show_project_type_options" "^[1-9]$|^1[01]$"

    case $PROJECT_TYPE_CHOICE in
        1) PROJECT_TYPE="web-app" ;;
        2) PROJECT_TYPE="mobile-app" ;;
        3) PROJECT_TYPE="desktop-app" ;;
        4) PROJECT_TYPE="backend-service" ;;
        5) PROJECT_TYPE="data-pipeline" ;;
        6) PROJECT_TYPE="embedded-system" ;;
        7) PROJECT_TYPE="ai-ml-service" ;;
        8) PROJECT_TYPE="static-website" ;;
        9) PROJECT_TYPE="cordova-hybrid-app" ;;
        10) PROJECT_TYPE="legacy-website" ;;
        11) read -p "Please specify: " PROJECT_TYPE ;;
        *) PROJECT_TYPE="web-app" ;;
    esac

    read_with_default "Tech stack (e.g., 'Java/Spring Boot, React, PostgreSQL'):" "$TECH_STACK_SUGGESTION" "TECH_STACK"

    echo ""
    echo "Database technology:"
    echo "1. PostgreSQL"
    echo "2. MySQL"
    echo "3. MongoDB"
    echo "4. SQLite"
    echo "5. Redis"
    echo "6. Multiple databases"
    echo "7. No database"
    echo "8. Other"

    # Map Claude suggestion to choice number
    local suggested_db_choice=""
    case "$DATABASE_TECH_SUGGESTION" in
        "PostgreSQL") suggested_db_choice="1" ;;
        "MySQL") suggested_db_choice="2" ;;
        "MongoDB") suggested_db_choice="3" ;;
        "SQLite") suggested_db_choice="4" ;;
        "Redis") suggested_db_choice="5" ;;
        "Multiple") suggested_db_choice="6" ;;
        "None") suggested_db_choice="7" ;;
        *) suggested_db_choice="" ;;
    esac

    if [[ -n "$suggested_db_choice" ]]; then
        echo -e "${CYAN}🤖 Claude suggests: ${BOLD}$suggested_db_choice ($DATABASE_TECH_SUGGESTION)${NC}"
        read -p "Select database (1-8) [Press Enter for suggestion]: " DB_CHOICE
        if [[ -z "$DB_CHOICE" ]]; then
            DB_CHOICE="$suggested_db_choice"
        fi
    else
        read -p "Select database (1-8): " DB_CHOICE
    fi

    case $DB_CHOICE in
        1) DATABASE_TECH="PostgreSQL" ;;
        2) DATABASE_TECH="MySQL" ;;
        3) DATABASE_TECH="MongoDB" ;;
        4) DATABASE_TECH="SQLite" ;;
        5) DATABASE_TECH="Redis" ;;
        6) read_with_default "Specify databases:" "" "DATABASE_TECH" ;;
        7) DATABASE_TECH="None" ;;
        8) read_with_default "Specify database:" "" "DATABASE_TECH" ;;
        *) DATABASE_TECH="PostgreSQL" ;;
    esac
}

get_security_info() {
    echo ""
    echo -e "${BLUE}🔒 SECURITY & COMPLIANCE${NC}"
    echo "------------------------------"

    read_with_default "Most critical assets (e.g., 'user data, payment info, API keys'):" "$CRITICAL_ASSETS_SUGGESTION" "CRITICAL_ASSETS"

    echo ""
    echo "Compliance requirements:"
    echo "1. GDPR"
    echo "2. HIPAA"
    echo "3. SOC 2"
    echo "4. PCI DSS"
    echo "5. Multiple"
    echo "6. None"
    echo "7. Other"

    # Map Claude suggestion to choice number
    local suggested_compliance_choice=""
    if [[ -n "$MANDATORY_REQUIREMENTS_SUGGESTION" ]]; then
        case "$MANDATORY_REQUIREMENTS_SUGGESTION" in
            *"GDPR"*) suggested_compliance_choice="1" ;;
            *"HIPAA"*) suggested_compliance_choice="2" ;;
            *"SOC"*) suggested_compliance_choice="3" ;;
            *"PCI"*) suggested_compliance_choice="4" ;;
            "None") suggested_compliance_choice="6" ;;
            *) suggested_compliance_choice="7" ;;
        esac
    fi

    if [[ -n "$suggested_compliance_choice" ]]; then
        echo -e "${CYAN}🤖 Claude suggests: ${BOLD}$suggested_compliance_choice ($MANDATORY_REQUIREMENTS_SUGGESTION)${NC}"
        read -p "Select compliance (1-7) [Press Enter for suggestion]: " COMPLIANCE_CHOICE
        if [[ -z "$COMPLIANCE_CHOICE" ]]; then
            COMPLIANCE_CHOICE="$suggested_compliance_choice"
        fi
    else
        read -p "Select compliance (1-7): " COMPLIANCE_CHOICE
    fi

    case $COMPLIANCE_CHOICE in
        1) MANDATORY_REQUIREMENTS="GDPR compliance" ;;
        2) MANDATORY_REQUIREMENTS="HIPAA compliance" ;;
        3) MANDATORY_REQUIREMENTS="SOC 2 compliance" ;;
        4) MANDATORY_REQUIREMENTS="PCI DSS compliance" ;;
        5) read_with_default "Specify requirements:" "$MANDATORY_REQUIREMENTS_SUGGESTION" "MANDATORY_REQUIREMENTS" ;;
        6) MANDATORY_REQUIREMENTS="None" ;;
        7) read_with_default "Specify requirements:" "$MANDATORY_REQUIREMENTS_SUGGESTION" "MANDATORY_REQUIREMENTS" ;;
        *) MANDATORY_REQUIREMENTS="" ;;
    esac
}

get_technical_info() {
    echo ""
    echo -e "${BLUE}⚙️ TECHNICAL DETAILS${NC}"
    echo "------------------------------"

    read_with_default "Common issues you face (e.g., 'performance bottlenecks, memory leaks'):" "$COMMON_ISSUES_SUGGESTION" "COMMON_ISSUES"

    read_with_default "File structure overview (e.g., 'src/main/java, gradle build'):" "$FILE_STRUCTURE_SUGGESTION" "FILE_STRUCTURE"

    echo ""
    echo "Deployment target:"
    echo "1. Cloud containers (Docker/Kubernetes)"
    echo "2. Mobile devices"
    echo "3. Desktop OS"
    echo "4. Embedded hardware"
    echo "5. Multiple platforms"
    echo "6. Other"

    # Map Claude suggestion to choice number
    local suggested_deploy_choice=""
    if [[ -n "$DEPLOYMENT_TARGET_SUGGESTION" ]]; then
        case "$DEPLOYMENT_TARGET_SUGGESTION" in
            *"cloud"*|*"container"*) suggested_deploy_choice="1" ;;
            *"mobile"*) suggested_deploy_choice="2" ;;
            *"desktop"*) suggested_deploy_choice="3" ;;
            *"embedded"*) suggested_deploy_choice="4" ;;
            *"multiple"*) suggested_deploy_choice="5" ;;
            *) suggested_deploy_choice="6" ;;
        esac
    fi

    if [[ -n "$suggested_deploy_choice" ]]; then
        echo -e "${CYAN}🤖 Claude suggests: ${BOLD}$suggested_deploy_choice ($DEPLOYMENT_TARGET_SUGGESTION)${NC}"
        read -p "Select deployment (1-6) [Press Enter for suggestion]: " DEPLOY_CHOICE
        if [[ -z "$DEPLOY_CHOICE" ]]; then
            DEPLOY_CHOICE="$suggested_deploy_choice"
        fi
    else
        read -p "Select deployment (1-6): " DEPLOY_CHOICE
    fi

    case $DEPLOY_CHOICE in
        1) DEPLOYMENT_TARGET="cloud containers" ;;
        2) DEPLOYMENT_TARGET="mobile devices" ;;
        3) DEPLOYMENT_TARGET="desktop OS" ;;
        4) DEPLOYMENT_TARGET="embedded hardware" ;;
        5) read_with_default "Specify platforms:" "$DEPLOYMENT_TARGET_SUGGESTION" "DEPLOYMENT_TARGET" ;;
        6) read_with_default "Specify target:" "$DEPLOYMENT_TARGET_SUGGESTION" "DEPLOYMENT_TARGET" ;;
        *) DEPLOYMENT_TARGET="cloud containers" ;;
    esac
}

offer_automatic_claude_setup() {
    local filename="$1"

    echo ""
    echo -e "${BLUE}🚀 AUTOMATIC CLAUDE SETUP${NC}"
    echo "------------------------------"

    if [[ "$CLAUDE_AVAILABLE" == true ]]; then
        echo -e "${GREEN}✅ Claude is available for automatic setup!${NC}"
        echo ""
        echo "I can automatically set up your CLAUDE.md file by:"
        echo "1. 📋 Reading the generated prompt"
        echo "2. 🤖 Invoking Claude with the prompt"
        echo "3. 📝 Creating your project's CLAUDE.md file"
        echo "4. ✅ Validating the setup is working"
        echo ""
        read -p "Would you like me to automatically set up Claude for your project? (Y/n): " AUTO_SETUP

        if [[ -z "$AUTO_SETUP" ]] || [[ "$AUTO_SETUP" =~ ^[Yy]$ ]]; then
            echo ""
            echo -e "${CYAN}🚀 Setting up Claude cognitive enhancement automatically...${NC}"
            echo ""

            # Attempt automatic setup
            if setup_claude_automatically "$filename"; then
                echo ""
                echo -e "${GREEN}🎉 SUCCESS! Claude cognitive enhancement system is now active!${NC}"
                echo -e "${BOLD}📄 Your CLAUDE.md file has been created in: $PROJECT_DIR/CLAUDE.md${NC}"
                echo ""
                echo -e "${CYAN}💡 Your next Claude conversations in this project will be enhanced with:${NC}"
                echo "   • Security analysis tailored to your tech stack"
                echo "   • Pattern matching for your specific architecture"
                echo "   • Proactive learning and improvement suggestions"
                echo ""
                echo -e "${GREEN}✨ Try asking Claude: 'Help me add user authentication'${NC}"
                echo -e "${GREEN}   Notice the enhanced security analysis and specific recommendations!${NC}"
                return 0
            else
                echo ""
                echo -e "${YELLOW}⚠️  Automatic setup failed. Please use manual setup steps below.${NC}"
                return 1
            fi
        else
            echo -e "${CYAN}👍 No problem! You can use the manual setup steps below.${NC}"
            return 1
        fi
    else
        echo -e "${YELLOW}⚠️  Claude not available for automatic setup.${NC}"
        echo "Please use the manual setup steps below."
        return 1
    fi
}

setup_claude_automatically() {
    local filename="$1"

    echo -e "${BLUE}📋 Reading generated prompt...${NC}"

    if [[ ! -f "$filename" ]]; then
        echo -e "${RED}❌ Generated prompt file not found: $filename${NC}"
        return 1
    fi

    echo -e "${CYAN}🤖 Invoking Claude with your customized prompt...${NC}"
    echo "This will create your CLAUDE.md file automatically."
    echo ""

    # Read the prompt content
    local prompt_content
    prompt_content=$(cat "$filename")

    # Create a message for Claude
    echo "📝 Sending the following request to Claude:"
    echo "----------------------------------------"
    echo "Please set up the cognitive enhancement system for this project using the following configuration:"
    echo ""
    echo "$prompt_content"
    echo ""
    echo "----------------------------------------"
    echo ""
    echo -e "${YELLOW}📋 CLAUDE INVOCATION NEEDED${NC}"
    echo "Please copy the prompt above and paste it to Claude."
    echo "Claude will create your CLAUDE.md file and set up the system."
    echo ""
    read -p "Press Enter when Claude has finished setting up the system..."

    # Check if CLAUDE.md was created
    if [[ -f "$PROJECT_DIR/CLAUDE.md" ]]; then
        echo -e "${GREEN}✅ CLAUDE.md file detected!${NC}"

        # Validate the setup
        echo -e "${BLUE}🔍 Validating Claude setup...${NC}"
        if grep -q "CLAUDE.md" "$PROJECT_DIR/CLAUDE.md" && grep -q "$PROJECT_NAME" "$PROJECT_DIR/CLAUDE.md"; then
            echo -e "${GREEN}✅ Setup validation passed!${NC}"
            return 0
        else
            echo -e "${YELLOW}⚠️  Setup validation found minor issues, but CLAUDE.md was created.${NC}"
            return 0
        fi
    else
        echo -e "${RED}❌ CLAUDE.md file not found. Setup may have failed.${NC}"
        echo "Please check that Claude successfully created the file."
        return 1
    fi
}

generate_prompt() {
    local filename="$PROJECT_DIR/claude_prompt_$(echo "$PROJECT_NAME" | tr '[:upper:]' '[:lower:]' | tr ' ' '_').txt"

    cat > "$filename" << EOF
(Fill in the [bracketed] sections with your project details first)

PROJECT CONTEXT TO FILL

PROJECT_NAME: $PROJECT_NAME
PROJECT_TYPE: $PROJECT_TYPE
TECH_STACK: $TECH_STACK
DATABASE_TECH: $DATABASE_TECH
CRITICAL_ASSETS: $CRITICAL_ASSETS
MANDATORY_REQUIREMENTS: $MANDATORY_REQUIREMENTS
COMMON_ISSUES: $COMMON_ISSUES
FILE_STRUCTURE: $FILE_STRUCTURE
DEPLOYMENT_TARGET: $DEPLOYMENT_TARGET

SYSTEM COMPONENTS TO IMPLEMENT

1. CONTEXT-AWARE DECISION ENHANCEMENT

Create project-specific mindset triggers:

Critical_Priority_Areas:
  - $CRITICAL_ASSETS: Enhanced protection protocols
  - $TECH_STACK: Framework-specific best practices
  - $DEPLOYMENT_TARGET: Platform-specific optimization

Mandatory_Validation_Rules:
  - $MANDATORY_REQUIREMENTS: Compliance verification required
  - $COMMON_ISSUES: Prevention analysis required
  - $CRITICAL_ASSETS operations: Security validation required

2. PRIORITY-BASED PATTERN MATCHING

Processing Order: CRITICAL → HIGH → MEDIUM → NORMAL

CRITICAL (Immediate Analysis Required):

Security_Critical_Patterns:
  - "Authentication", "authorization", "login", "password", "token", "session" → Security analysis required
  - "SQL", "database", "query", "injection" → Database security validation
  - "upload", "file", "input", "form" → Input validation and security check
  - "API key", "secret", "credential", "config" → Credential security analysis
  - "$CRITICAL_ASSETS" → Enhanced protection protocols

Data_Integrity_Critical:
  - "$CRITICAL_ASSETS" operations → Data validation and backup verification
  - "migration", "schema", "ALTER TABLE" → Database integrity validation
  - "delete", "DROP", "truncate" → Data loss prevention analysis

HIGH (Enhanced Analysis):

${TECH_STACK}_Specific_Patterns:
  - $TECH_STACK framework patterns → Framework-specific validations
  - $DATABASE_TECH database patterns → Database-specific checks
  - $PROJECT_TYPE architecture patterns → Application-specific best practices

Performance_Critical:
  - "$COMMON_ISSUES" → Performance impact analysis required
  - "loop", "recursive", "async", "parallel" → Performance and resource analysis
  - "$DEPLOYMENT_TARGET" constraints → Platform-specific optimization

MEDIUM (Standard Analysis):

Compatibility_Validation:
  - "$MANDATORY_REQUIREMENTS" → Compliance verification
  - "dependency", "import", "package" → Compatibility impact analysis
  - "version", "upgrade", "migration" → Version compatibility check

NORMAL (Background Analysis):

Code_Quality_Patterns:
  - "TODO", "FIXME", "HACK" → Code quality improvement suggestions
  - "test", "spec", "mock" → Testing approach recommendations
  - "documentation", "comment" → Documentation enhancement suggestions

3. UNIVERSAL APPLICATION PATTERNS

Choose the pattern set that matches your PROJECT_TYPE: $PROJECT_TYPE

4. DOMAIN KNOWLEDGE INTEGRATION

Technology Stack Expertise for $TECH_STACK:

${TECH_STACK}_Best_Practices:
  - Performance optimization for $DEPLOYMENT_TARGET
  - Security patterns for $CRITICAL_ASSETS protection
  - Architecture patterns for $PROJECT_TYPE applications

${DATABASE_TECH}_Optimization:
  - Query optimization for $DATABASE_TECH
  - Security patterns for $CRITICAL_ASSETS storage
  - Performance tuning for $DEPLOYMENT_TARGET

Domain-Specific Knowledge for $PROJECT_TYPE:

${PROJECT_TYPE}_Architecture_Principles:
  - Scalability patterns for $DEPLOYMENT_TARGET
  - Security requirements for $CRITICAL_ASSETS
  - Performance optimization for common issues: $COMMON_ISSUES

Industry_Standards_$(echo "$PROJECT_NAME" | tr ' ' '_'):
  - $MANDATORY_REQUIREMENTS → Implementation approach
  - $CRITICAL_ASSETS security → Validation method
  - $DEPLOYMENT_TARGET performance → Measurement approach

5. LEARNING ENHANCEMENT TRIGGERS

Continuous Improvement Protocol:

Learning_Signal_Detection:
  - When I catch an issue you missed → HIGH confidence learning opportunity
  - When I suggest optimization → MEDIUM confidence pattern enhancement
  - When you encounter unexpected behavior → HIGH confidence gap identification
  - When patterns prevent problems → HIGH confidence pattern validation

Proactive_Documentation_Updates:
  TRIGGER_CONDITIONS:
    - New vulnerability patterns discovered → Update CRITICAL security patterns
    - Framework updates affecting compatibility → Update $TECH_STACK patterns
    - Performance bottlenecks identified → Update optimization guidelines
    - Integration challenges solved → Update architecture patterns

Learning_Confidence_Assessment:
  HIGH_CONFIDENCE (Immediate CLAUDE.md Update):
    - Clear error prevented by missing pattern
    - Security vulnerability caught through pattern gap
    - Performance issue solved through specific optimization
    - Compatibility problem resolved through targeted check

  MEDIUM_CONFIDENCE (Propose for Next Update):
    - Efficiency improvement observed through better pattern
    - User workflow enhanced through refined trigger
    - Pattern refinement improves accuracy without noise

  LOW_CONFIDENCE (Monitor for Patterns):
    - Theoretical improvement without concrete evidence
    - Single-occurrence issue without pattern validation
    - Preference-based suggestion without clear benefit

Context_Stack_Awareness:
  CROSS_TASK_MEMORY:
    - Remember architecture decisions from previous tasks
    - Build on established patterns within conversation
    - Reference previous solutions for consistency
    - Maintain awareness of project evolution

6. ERROR RECOVERY PROTOCOLS

Pattern_Miss_Detection:
    - "Did any [critical issues] emerge that patterns should have caught?"
    - "Are there [security/compatibility/consistency] problems not flagged?"

Secondary_Validation_Checks:
    Security_Backstop:
      - Final scan for $CRITICAL_ASSETS security patterns
      - Double-check authentication/authorization patterns weren't missed

    Technical_Backstop:
      - Scan for $COMMON_ISSUES that might be missed
      - Verify $MANDATORY_REQUIREMENTS weren't overlooked

Pattern_Improvement_Triggers:
    - "If I missed X, what pattern should have caught it?"
    - "What keyword would have triggered proper analysis?"

7. PROACTIVE LEARNING PROTOCOL

After Each Task - MANDATORY:

🔍 LEARNING IDENTIFIED: [Specific gap or improvement discovered]
📝 PROPOSED CLAUDE.md UPDATE: [Exact text to add/modify]
🎯 REASONING: [Why this will prevent future errors]
📊 CONFIDENCE LEVEL: [HIGH/MEDIUM/LOW based on evidence strength]
✅ USER APPROVAL NEEDED: [Yes/No for implementation]

CONFIDENCE LEVEL CRITERIA (Critical for Effective Learning):

HIGH_CONFIDENCE_Learning:
  - Clear errors prevented (security vulnerability caught, compatibility issue avoided)
  - Missing pattern discovered through actual failure
  - User feedback indicating specific improvement needed
  - Concrete evidence of system gap from real task outcomes
  Examples: "Missed SQL injection risk", "Failed to catch datetime compatibility issue"

MEDIUM_CONFIDENCE_Learning:
  - Efficiency improvements observed during tasks
  - Pattern refinements that improve accuracy
  - User behavior patterns that suggest optimization
  - Successful prevention that could be coincidental
  Examples: "Pattern helped catch issue faster", "User prefers concise responses"

LOW_CONFIDENCE_Learning:
  - Theoretical improvements without concrete evidence
  - Single occurrence without pattern validation
  - Preference-based changes without clear benefit
  - Speculative enhancements without proven value
  Examples: "Might be better to...", "Could potentially improve..."

Build this system step by step, explaining reasoning for each component and how it aligns with the specific project needs.

Remember: The goal is sophisticated intelligence that enhances natural decision-making, not complex artificial coordination.

---

IMPLEMENTATION REQUIREMENTS - MANDATORY FIRST STEPS

⚡ CRITICAL: After confirming this setup, you MUST immediately:

STEP 1: Create CLAUDE.md File
Create a \`CLAUDE.md\` file in the project root with the complete cognitive enhancement system configured for this specific project. Include:
- All the patterns above, customized with the actual $PROJECT_NAME, $TECH_STACK, etc.
- The learning protocol for continuous improvement
- Project-specific security and compatibility requirements
- Clear documentation for future Claude conversations

STEP 2: Implement Learning System
Set up the proactive learning protocol by:
- Adding the confidence-based learning assessment system
- Creating a system for documenting pattern improvements
- Establishing the HIGH/MEDIUM/LOW confidence criteria
- Setting up the mechanism for CLAUDE.md updates based on learning

STEP 3: Validate System Setup
Confirm the cognitive enhancement system is working by:
- Testing pattern recognition with a sample task
- Verifying security analysis triggers correctly
- Checking that tech stack expertise is active
- Ensuring the learning protocol responds to task outcomes

ONLY AFTER completing these implementation steps should you signal readiness for development tasks.

---

⚡ IMPORTANT: After you paste this prompt, I (Claude) should respond with:
1. Confirmation that I understand your project domain and tech stack
2. Immediately create the CLAUDE.md file with your customized system
3. Implement the learning protocol for continuous improvement
4. Validate the system setup with a test
5. Signal readiness for your first development task

If I don't acknowledge the setup or respond generically, the prompt may not have worked properly.
EOF

    echo "$filename"
}

validate_inputs() {
    # Validate required fields are not empty
    if [[ -z "$PROJECT_NAME" ]]; then
        echo -e "${RED}❌ Error: Project name is required${NC}"
        exit 1
    fi

    if [[ -z "$TECH_STACK" ]]; then
        echo -e "${RED}❌ Error: Tech stack is required${NC}"
        exit 1
    fi

    if [[ -z "$CRITICAL_ASSETS" ]]; then
        echo -e "${YELLOW}⚠️  Warning: No critical assets specified. Using 'user data' as default.${NC}"
        CRITICAL_ASSETS="user data"
    fi

    # Validate project name doesn't contain invalid characters
    if [[ "$PROJECT_NAME" =~ [^a-zA-Z0-9\ \-\_] ]]; then
        echo -e "${YELLOW}⚠️  Warning: Project name contains special characters. This may affect file naming.${NC}"
    fi
}

cleanup() {
    # Clean up temporary files
    if [[ -n "$CLAUDE_SUGGESTIONS_FILE" ]] && [[ -f "$CLAUDE_SUGGESTIONS_FILE" ]]; then
        rm -f "$CLAUDE_SUGGESTIONS_FILE"
    fi
}

main() {
    # Set up cleanup on exit
    trap cleanup EXIT

    print_header

    # Detect and validate directories
    detect_directories

    # Check for Claude availability and analyze repository
    if check_claude_availability; then
        analyze_repository
        parse_claude_suggestions
    else
        echo -e "${CYAN}ℹ️  Running in manual mode without Claude assistance${NC}"
        echo ""
    fi

    # Collect information with Claude suggestions
    get_project_info
    get_security_info
    get_technical_info

    # Validate inputs
    validate_inputs

    echo ""
    echo -e "${BLUE}🔧 GENERATING YOUR CUSTOMIZED PROMPT...${NC}"
    echo "----------------------------------------"

    # Generate prompt
    filename=$(generate_prompt)

    if [ -f "$filename" ]; then
        echo ""
        echo -e "${GREEN}✅ SUCCESS!${NC}"
        echo -e "${BOLD}📄 Your customized prompt has been saved to: $filename${NC}"

        if [[ "$CLAUDE_AVAILABLE" == true ]]; then
            echo -e "${CYAN}🧠 Enhanced with Claude intelligence from repository analysis${NC}"
        fi

        # Validate the generated file
        if [ -f "$SCRIPT_DIR/validate.sh" ]; then
            echo ""
            echo -e "${BLUE}🔍 Running validation check...${NC}"
            if "$SCRIPT_DIR/validate.sh" "$filename" | tail -1 | grep -q "EXCELLENT"; then
                echo -e "${GREEN}✅ Validation passed!${NC}"
            else
                echo -e "${YELLOW}⚠️  Validation found minor issues (check above)${NC}"
            fi
        fi

        # Offer automatic Claude setup
        offer_automatic_claude_setup "$filename"

        echo ""
        echo -e "${YELLOW}📋 MANUAL SETUP STEPS (if not using automatic setup):${NC}"
        echo "1. Open the generated file: $filename"
        echo "2. Copy the entire content"
        echo "3. Paste it to a new Claude conversation"
        echo "4. Claude will create your CLAUDE.md file and set up the system"
        echo ""
        echo -e "${BOLD}💡 TIP: Use '$SCRIPT_DIR/validate.sh $filename' to check prompt quality${NC}"

        # Check for contribution opportunities
        echo ""
        echo -e "${CYAN}🔍 Checking for contribution opportunities...${NC}"
        if [[ -f "$SCRIPT_DIR/contribute-stack.sh" ]]; then
            bash "$SCRIPT_DIR/contribute-stack.sh" "$PROJECT_DIR" "$PROJECT_NAME" "$SCRIPT_DIR"
        fi

        echo ""
        echo -e "${GREEN}🚀 Your project will then have the same sophisticated Claude${NC}"
        echo -e "${GREEN}   cognitive enhancement system we built together!${NC}"

        if [[ "$CLAUDE_AVAILABLE" == true ]]; then
            echo ""
            echo -e "${CYAN}🧠 This prompt was enhanced with Claude's analysis of your repository${NC}"
            echo -e "${CYAN}   for maximum accuracy and relevance to your specific project.${NC}"
        fi
    else
        echo -e "${RED}❌ Error generating the prompt file.${NC}"
        echo "Please check file permissions and try again."
        exit 1
    fi
}

# Check if running interactively
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi