#!/bin/bash
#
# Claude-Ally Setup UI Module
# User interface functions: prompts, options, menus, and input handling
#

# Read input with default value
read_with_default() {
    local prompt="$1"
    local default="$2"
    local result

    if [[ "${NON_INTERACTIVE:-false}" == "true" ]]; then
        result="$default"
        echo >&2 "$prompt$default (non-interactive mode)"
    else
        read -r -p "$prompt" result || {
            echo -e "\n\033[1;33m⚠️  Input interrupted by user.\033[0m"
            exit 130
        }
        if [[ -z "$result" ]]; then
            result="$default"
        fi
    fi

    printf '%s' "$result"
}

# Read input with Claude suggestion
read_with_suggestion() {
    local prompt="$1"
    local suggestion="$2"
    local result

    if [[ -n "$suggestion" ]]; then
        echo -e "${CYAN}🤖 Claude suggests: $suggestion${NC}" >&2
        prompt="$prompt [Press Enter for suggestion or type new value]: "
    fi

    if [[ "${NON_INTERACTIVE:-false}" == "true" ]]; then
        result="$suggestion"
        echo >&2 "$prompt$suggestion (non-interactive mode)"
    else
        read -r -p "$prompt" result || {
            echo -e "\n\033[1;33m⚠️  Input interrupted by user.\033[0m"
            exit 130
        }
        if [[ -z "$result" ]] && [[ -n "$suggestion" ]]; then
            result="$suggestion"
        fi
    fi

    printf '%s' "$result"
}

# Show database options
show_database_options() {
    echo ""
    echo -e "${CYAN}Database Options:${NC}"
    echo "1. PostgreSQL"
    echo "2. MySQL"
    echo "3. SQLite"
    echo "4. MongoDB"
    echo "5. Redis"
    echo "6. Multiple databases"
    echo "7. No database"
    echo "8. Other/Custom"
}

# Show tech stack options
show_tech_stack_options() {
    echo ""
    echo -e "${CYAN}Common Tech Stack Patterns:${NC}"
    echo "1. React + Node.js + PostgreSQL"
    echo "2. Vue.js + Express + MongoDB"
    echo "3. Python Django + PostgreSQL"
    echo "4. Python FastAPI + SQLAlchemy"
    echo "5. Java Spring Boot + MySQL"
    echo "6. Go + PostgreSQL"
    echo "7. Rust + Actix + PostgreSQL"
    echo "8. Next.js + Prisma + PostgreSQL"
    echo "9. Custom/Other"
}

# Show critical assets options
show_critical_assets_options() {
    echo ""
    echo -e "${CYAN}Common Critical Assets:${NC}"
    echo "1. User data (PII, passwords, emails)"
    echo "2. Payment information"
    echo "3. API keys and secrets"
    echo "4. Configuration files"
    echo "5. Database credentials"
    echo "6. Source code"
    echo "7. Business logic"
    echo "8. Custom/Other"
}

# Show common issues options
show_common_issues_options() {
    echo ""
    echo -e "${CYAN}Common Technical Issues:${NC}"
    echo "1. Authentication and authorization"
    echo "2. Input validation and sanitization"
    echo "3. Database performance"
    echo "4. API rate limiting"
    echo "5. Memory leaks"
    echo "6. Error handling"
    echo "7. Configuration management"
    echo "8. Custom/Other"
}

# Show compliance options
show_compliance_options() {
    echo ""
    echo -e "${CYAN}Compliance Requirements:${NC}"
    echo "1. GDPR (EU data protection)"
    echo "2. HIPAA (Healthcare)"
    echo "3. PCI DSS (Payment processing)"
    echo "4. SOX (Financial reporting)"
    echo "5. ISO 27001 (Information security)"
    echo "6. Internal company policies"
    echo "7. No specific compliance"
    echo "8. Custom/Other"
}

# Show file structure options
show_file_structure_options() {
    echo ""
    echo -e "${CYAN}Project Structure Patterns:${NC}"
    echo "1. MVC (Model-View-Controller)"
    echo "2. Clean Architecture"
    echo "3. Hexagonal Architecture"
    echo "4. Microservices"
    echo "5. Monolithic"
    echo "6. Component-based"
    echo "7. Domain-driven design"
    echo "8. Custom/Other"
}

# Show deployment options
show_deployment_options() {
    echo ""
    echo -e "${CYAN}Deployment Environments:${NC}"
    echo "1. AWS (Amazon Web Services)"
    echo "2. Azure (Microsoft Azure)"
    echo "3. GCP (Google Cloud Platform)"
    echo "4. Docker containers"
    echo "5. Kubernetes"
    echo "6. Traditional servers"
    echo "7. Serverless (Lambda, Functions)"
    echo "8. Custom/Other"
}

# Show project type options
show_project_type_options() {
    echo ""
    echo -e "${CYAN}Project Types:${NC}"
    echo "1. Web Application (Frontend + Backend)"
    echo "2. Mobile Application"
    echo "3. Backend API Service"
    echo "4. Desktop Application"
    echo "5. CLI Tool/Utility"
    echo "6. Library/Package"
    echo "7. Data Science/ML Project"
    echo "8. Other"
}

# Get project information
get_project_info() {
    echo -e "${BLUE}📋 Project Information${NC}"
    echo "=============================="

    # Project name
    local default_name
    default_name=$(basename "$PROJECT_DIR")
    local claude_suggestion=""

    if [[ -f "$CLAUDE_SUGGESTIONS_FILE" ]]; then
        claude_suggestion=$(grep "PROJECT_NAME_SUGGESTION:" "$CLAUDE_SUGGESTIONS_FILE" 2>/dev/null | cut -d: -f2- | xargs || echo "")
    fi

    if [[ -n "$claude_suggestion" ]]; then
        PROJECT_NAME=$(read_with_suggestion "Project name: " "$claude_suggestion")
    else
        PROJECT_NAME=$(read_with_default "Project name [$default_name]: " "$default_name")
    fi

    # Project type
    show_project_type_options
    if [[ -f "$CLAUDE_SUGGESTIONS_FILE" ]]; then
        claude_suggestion=$(grep "PROJECT_TYPE_SUGGESTION:" "$CLAUDE_SUGGESTIONS_FILE" 2>/dev/null | cut -d: -f2- | xargs || echo "")
        if [[ -n "$claude_suggestion" ]]; then
            echo -e "${CYAN}🤖 Claude suggests: 1 ($claude_suggestion)${NC}"
        fi
    fi

    if [[ "${NON_INTERACTIVE:-false}" == "true" ]]; then
        PROJECT_TYPE_NUM="1"
        echo "Select project type (1-8) [1]: 1 (non-interactive mode)"
    else
        read -r -p "Select project type (1-8) [1]: " PROJECT_TYPE_NUM || {
            echo -e "\n\033[1;33m⚠️  Input interrupted by user.\033[0m"
            exit 130
        }
    fi
    PROJECT_TYPE_NUM=${PROJECT_TYPE_NUM:-1}

    case $PROJECT_TYPE_NUM in
        1) PROJECT_TYPE="web-app" ;;
        2) PROJECT_TYPE="mobile-app" ;;
        3) PROJECT_TYPE="backend-service" ;;
        4) PROJECT_TYPE="desktop-app" ;;
        5) PROJECT_TYPE="cli-tool" ;;
        6) PROJECT_TYPE="library" ;;
        7) PROJECT_TYPE="data-science" ;;
        *) PROJECT_TYPE="other" ;;
    esac
}

# Get security information
get_security_info() {
    echo ""
    echo -e "${BLUE}🔐 Security & Compliance${NC}"
    echo "=============================="

    # Critical assets
    show_critical_assets_options
    if [[ "${NON_INTERACTIVE:-false}" == "true" ]]; then
        CRITICAL_ASSETS="user data, configuration files"
        echo "Critical assets [user data]: user data, configuration files (non-interactive mode)"
    else
        read -r -p "Critical assets (comma-separated or describe): " CRITICAL_ASSETS || {
            echo -e "\n\033[1;33m⚠️  Input interrupted by user.\033[0m"
            exit 130
        }
    fi
    CRITICAL_ASSETS=${CRITICAL_ASSETS:-"user data"}

    # Compliance requirements
    show_compliance_options
    if [[ "${NON_INTERACTIVE:-false}" == "true" ]]; then
        COMPLIANCE="7"
        echo "Compliance requirements [7]: 7 (non-interactive mode)"
    else
        read -r -p "Compliance requirements (1-8) [7]: " COMPLIANCE || {
            echo -e "\n\033[1;33m⚠️  Input interrupted by user.\033[0m"
            exit 130
        }
    fi
    COMPLIANCE=${COMPLIANCE:-7}
}

# Get technical information
get_technical_info() {
    echo ""
    echo -e "${BLUE}⚙️  Technical Details${NC}"
    echo "=============================="

    # Tech stack
    local claude_suggestion=""
    if [[ -f "$CLAUDE_SUGGESTIONS_FILE" ]]; then
        claude_suggestion=$(grep "TECH_STACK_SUGGESTION:" "$CLAUDE_SUGGESTIONS_FILE" 2>/dev/null | cut -d: -f2- | xargs || echo "")
    fi

    if [[ -n "$claude_suggestion" ]]; then
        TECH_STACK=$(read_with_suggestion "Tech stack: " "$claude_suggestion")
    else
        show_tech_stack_options
        if [[ "${NON_INTERACTIVE:-false}" == "true" ]]; then
            TECH_STACK="React + Node.js + PostgreSQL"
            echo "Tech stack [React + Node.js]: React + Node.js + PostgreSQL (non-interactive mode)"
        else
            read -r -p "Tech stack (describe or select): " TECH_STACK || {
                echo -e "\n\033[1;33m⚠️  Input interrupted by user.\033[0m"
                exit 130
            }
        fi
        TECH_STACK=${TECH_STACK:-"React + Node.js"}
    fi

    # Common issues
    show_common_issues_options
    if [[ "${NON_INTERACTIVE:-false}" == "true" ]]; then
        COMMON_ISSUES="authentication, input validation, error handling"
        echo "Common issues [authentication]: authentication, input validation, error handling (non-interactive mode)"
    else
        read -r -p "Common issues (comma-separated): " COMMON_ISSUES || {
            echo -e "\n\033[1;33m⚠️  Input interrupted by user.\033[0m"
            exit 130
        }
    fi
    COMMON_ISSUES=${COMMON_ISSUES:-"authentication, input validation"}
}