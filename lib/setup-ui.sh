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

# Simple but robust interactive selection with options
interactive_select_with_options() {
    local prompt="$1"
    local suggestion="$2"
    shift 2
    local -a options=("$@")
    local result

    # Non-interactive mode
    if [[ "${NON_INTERACTIVE:-false}" == "true" ]]; then
        result="$suggestion"
        echo "$prompt$suggestion (non-interactive mode)" >&2
        printf '%s' "$result"
        return 0
    fi

    # Check terminal capabilities
    if [[ ! -t 0 ]] || ! command -v tput >/dev/null 2>&1; then
        # Fallback to simple input
        result=$(read_with_suggestion "$prompt" "$suggestion")
        printf '%s' "$result"
        return 0
    fi

    # Interactive mode
    local -a full_options=()
    for opt in "${options[@]}"; do
        full_options+=("$opt")
    done
    full_options+=("Type custom input")

    local selected=0
    local num_options=${#full_options[@]}

    # Save terminal state
    local old_stty
    old_stty=$(stty -g 2>/dev/null) || old_stty=""

    # Setup terminal
    tput civis 2>/dev/null || true
    stty -echo -icanon 2>/dev/null || true

    # Cleanup function
    cleanup() {
        tput cnorm 2>/dev/null || true
        if [[ -n "$old_stty" ]]; then
            stty "$old_stty" 2>/dev/null || true
        else
            stty echo icanon 2>/dev/null || true
        fi
    }

    # Set trap
    trap cleanup EXIT INT TERM

    while true; do
        # Clear and display
        clear
        echo -e "${CYAN}$prompt${NC}"
        echo ""
        if [[ -n "$suggestion" ]]; then
            echo -e "${CYAN}🤖 Claude suggests: $suggestion${NC}"
            echo ""
        fi

        for i in "${!full_options[@]}"; do
            if [[ $i -eq $selected ]]; then
                echo -e "  ${GREEN}► $((i+1)). ${full_options[$i]}${NC}"
            else
                echo "    $((i+1)). ${full_options[$i]}"
            fi
        done

        echo ""
        echo -e "${YELLOW}↑↓ arrows, Enter to select"
        if [[ -n "$suggestion" ]]; then
            echo -e "Press 's' for Claude suggestion"
        fi
        echo -e "Press 'q' to quit${NC}"

        # Read key
        read -r -s -n1 key 2>/dev/null || key=""

        case "$key" in
            $'\x1b') # Arrow keys
                read -r -s -n2 arrow 2>/dev/null || arrow=""
                case "$arrow" in
                    '[A') [[ $selected -gt 0 ]] && ((selected--)) ;;
                    '[B') [[ $selected -lt $((num_options-1)) ]] && ((selected++)) ;;
                esac
                ;;
            '') # Enter
                cleanup
                trap - EXIT INT TERM
                echo ""
                if [[ $selected -eq $((num_options-1)) ]]; then
                    echo -e "${CYAN}Enter your input:${NC}"
                    read -r -p "> " result
                else
                    result="${full_options[$selected]}"
                fi
                printf '%s' "$result"
                return 0
                ;;
            's'|'S')
                if [[ -n "$suggestion" ]]; then
                    cleanup
                    trap - EXIT INT TERM
                    echo ""
                    printf '%s' "$suggestion"
                    return 0
                fi
                ;;
            'q'|'Q')
                cleanup
                trap - EXIT INT TERM
                echo ""
                echo -e "${YELLOW}Cancelled${NC}"
                exit 0
                ;;
        esac
    done
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

# Map detected project types to standard categories
map_detected_project_type() {
    local detected_type="$1"

    case "$detected_type" in
        "web-app"|"nextjs-ai-app"|"vue-app"|"react-app"|"svelte-app") echo "1" ;;
        "mobile-app"|"cordova-hybrid-app"|"react-native-app"|"flutter-app") echo "2" ;;
        "backend-service"|"api-service"|"ai-ml-service"|"microservice") echo "3" ;;
        "desktop-app"|"electron-app"|"tauri-app") echo "4" ;;
        "cli-tool"|"bash-cli"|"python-cli"|"node-cli") echo "5" ;;
        "library"|"package"|"npm-package"|"python-package") echo "6" ;;
        "data-science"|"ml-project"|"jupyter-project") echo "7" ;;
        *) echo "8" ;;
    esac
}

# Get human-readable description for detected project type
get_project_type_description() {
    local detected_type="$1"

    case "$detected_type" in
        "nextjs-ai-app") echo "Next.js AI Application" ;;
        "cordova-hybrid-app") echo "Cordova Hybrid Mobile App" ;;
        "ai-ml-service") echo "AI/ML Backend Service" ;;
        "bash-cli") echo "Bash CLI Tool" ;;
        "python-cli") echo "Python CLI Tool" ;;
        "vue-app") echo "Vue.js Application" ;;
        "react-app") echo "React Application" ;;
        "svelte-app") echo "Svelte Application" ;;
        "react-native-app") echo "React Native App" ;;
        "flutter-app") echo "Flutter App" ;;
        "electron-app") echo "Electron Desktop App" ;;
        "tauri-app") echo "Tauri Desktop App" ;;
        "npm-package") echo "NPM Package" ;;
        "python-package") echo "Python Package" ;;
        "jupyter-project") echo "Jupyter Notebook Project" ;;
        "kotlin-multiplatform-mobile") echo "Kotlin Multiplatform Mobile App" ;;
        "kotlin-multiplatform-desktop") echo "Kotlin Multiplatform Desktop App" ;;
        "kotlin-multiplatform") echo "Kotlin Multiplatform Project" ;;
        *) echo "$detected_type" ;;
    esac
}

# Interactive Y/n choice
show_interactive_yn() {
    local prompt="$1"
    local default="${2:-Y}" # Default to Y if not specified

    # Check if terminal supports interactive features
    if [[ ! -t 0 ]] || [[ "${NON_INTERACTIVE:-false}" == "true" ]] || ! command -v tput >/dev/null 2>&1; then
        return 1 # Fallback to traditional prompt
    fi

    local selected=0
    if [[ "$default" == "n" ]] || [[ "$default" == "N" ]]; then
        selected=1 # Start with No selected
    fi

    # Hide cursor and enable raw mode
    tput civis 2>/dev/null || true
    stty -echo 2>/dev/null || true

    cleanup_yn() {
        tput cnorm 2>/dev/null || true
        stty echo 2>/dev/null || true
    }
    trap cleanup_yn EXIT

    while true; do
        # Clear and redraw choice
        echo -e "\033[2J\033[H" # Clear screen and move to top
        echo -e "${CYAN}$prompt${NC}"
        echo ""

        if [[ $selected -eq 0 ]]; then
            echo -e "  ${GREEN}► Yes${NC}"
            echo "    No"
        else
            echo "    Yes"
            echo -e "  ${GREEN}► No${NC}"
        fi

        echo ""
        echo -e "${YELLOW}Use ↑/↓ arrows to navigate, Enter to select, 'q' to quit${NC}"

        # Read single character
        IFS= read -r -s -n1 char

        case "$char" in
            $'\x1b') # ESC sequence
                read -r -s -n2 char
                case "$char" in
                    '[A'|'[B') # Up or down arrow
                        selected=$((1 - selected)) # Toggle between 0 and 1
                        ;;
                esac
                ;;
            '') # Enter
                cleanup_yn
                trap - EXIT
                echo "" # Clear line after selection
                YN_SELECTION=$selected
                return 0
                ;;
            'y'|'Y') # Direct Y
                cleanup_yn
                trap - EXIT
                echo ""
                YN_SELECTION=0
                return 0
                ;;
            'n'|'N') # Direct N
                cleanup_yn
                trap - EXIT
                echo ""
                YN_SELECTION=1
                return 0
                ;;
            'q'|'Q') # Quit
                cleanup_yn
                trap - EXIT
                echo ""
                echo -e "${YELLOW}Setup cancelled by user${NC}"
                exit 0
                ;;
        esac
    done
}

# Universal interactive choice selector
show_interactive_choice() {
    local prompt="$1"
    shift
    local -a choices=("$@")
    local selected=0
    local num_choices=${#choices[@]}

    # Check if terminal supports interactive features
    if [[ ! -t 0 ]] || [[ "${NON_INTERACTIVE:-false}" == "true" ]]; then
        # Fallback to traditional prompt for non-interactive mode
        return 1 # Indicates fallback should be used
    fi

    # Check for required commands
    if ! command -v tput >/dev/null 2>&1; then
        return 1 # Fallback to traditional prompt
    fi

    # Save original terminal settings
    local original_settings
    original_settings=$(stty -g 2>/dev/null || echo "")

    # Hide cursor and enable raw mode
    tput civis 2>/dev/null || true
    stty -echo -icanon min 1 time 0 2>/dev/null || true

    cleanup_choice() {
        # Restore cursor and normal mode
        tput cnorm 2>/dev/null || true
        if [[ -n "$original_settings" ]]; then
            stty "$original_settings" 2>/dev/null || true
        else
            stty echo icanon 2>/dev/null || true
        fi
    }
    trap cleanup_choice EXIT

    while true; do
        # Clear and redraw choice
        echo -e "\033[2J\033[H" # Clear screen and move to top
        echo -e "${CYAN}$prompt${NC}"
        echo ""

        for i in "${!choices[@]}"; do
            if [[ $i -eq $selected ]]; then
                echo -e "  ${GREEN}► ${choices[$i]}${NC}"
            else
                echo "    ${choices[$i]}"
            fi
        done

        echo ""
        echo -e "${YELLOW}Use ↑/↓ arrows to navigate, Enter to select, 'q' to quit${NC}"

        # Read single character
        IFS= read -r -s -n1 char

        case "$char" in
            $'\x1b') # ESC sequence
                read -r -s -n2 char
                case "$char" in
                    '[A') # Up arrow
                        if [[ $selected -gt 0 ]]; then
                            ((selected--))
                        fi
                        ;;
                    '[B') # Down arrow
                        if [[ $selected -lt $((num_choices - 1)) ]]; then
                            ((selected++))
                        fi
                        ;;
                esac
                ;;
            '') # Enter
                cleanup_choice
                trap - EXIT
                echo "" # Clear line after selection
                CHOICE_SELECTION=$selected
                return 0
                ;;
            'q'|'Q') # Quit
                cleanup_choice
                trap - EXIT
                echo ""
                echo -e "${YELLOW}Setup cancelled by user${NC}"
                exit 0
                ;;
        esac
    done
}

# Interactive menu with Claude suggestions support
show_interactive_menu_with_suggestions() {
    local suggestion="$1"
    shift
    local -a options=("$@")
    local selected=0
    local num_options=${#options[@]}

    # Check if terminal supports interactive features
    if [[ ! -t 0 ]] || [[ "${NON_INTERACTIVE:-false}" == "true" ]]; then
        # Non-interactive mode - return the suggestion or first option
        if [[ -n "$suggestion" ]]; then
            echo "$suggestion"
        else
            echo "${options[0]}"
        fi
        return 0
    fi

    # Save original terminal settings
    local original_settings
    original_settings=$(stty -g 2>/dev/null || echo "")

    # Hide cursor and enable raw mode
    tput civis 2>/dev/null || true
    stty -echo -icanon min 1 time 0 2>/dev/null || true

    cleanup_menu() {
        tput cnorm 2>/dev/null || true
        if [[ -n "$original_settings" ]]; then
            stty "$original_settings" 2>/dev/null || true
        else
            stty echo icanon 2>/dev/null || true
        fi
    }
    trap cleanup_menu EXIT

    while true; do
        # Clear and redraw menu
        echo -e "\033[2J\033[H" # Clear screen and move to top

        if [[ -n "$suggestion" ]]; then
            echo -e "${CYAN}🤖 Claude suggests: $suggestion${NC}"
            echo ""
        fi

        echo -e "${CYAN}Use ↑↓ arrows, Enter to select:${NC}"
        echo ""

        for i in "${!options[@]}"; do
            local option_text="$((i+1)). ${options[$i]}"
            if [[ $i -eq $selected ]]; then
                echo -e "  ${GREEN}► $option_text${NC}"
            else
                echo "    $option_text"
            fi
        done

        echo ""
        if [[ -n "$suggestion" ]]; then
            echo -e "${BLUE}Press 's' to use Claude suggestion directly${NC}"
        fi
        echo -e "${YELLOW}Use ↑/↓ arrows to navigate, Enter to select, 'q' to quit${NC}"

        # Read single character
        IFS= read -r -s -n1 char

        case "$char" in
            $'\x1b') # ESC sequence
                read -r -s -n2 char
                case "$char" in
                    '[A') # Up arrow
                        if [[ $selected -gt 0 ]]; then
                            ((selected--))
                        fi
                        ;;
                    '[B') # Down arrow
                        if [[ $selected -lt $((num_options - 1)) ]]; then
                            ((selected++))
                        fi
                        ;;
                esac
                ;;
            '') # Enter
                cleanup_menu
                trap - EXIT
                echo ""
                MENU_SELECTION=$selected
                echo "${options[$selected]}"
                return 0
                ;;
            's'|'S') # Use suggestion
                if [[ -n "$suggestion" ]]; then
                    cleanup_menu
                    trap - EXIT
                    echo ""
                    echo "$suggestion"
                    return 0
                fi
                ;;
            'q'|'Q') # Quit
                cleanup_menu
                trap - EXIT
                echo ""
                echo -e "${YELLOW}Setup cancelled by user${NC}"
                exit 0
                ;;
        esac
    done
}

# Interactive menu for project types (special case)
show_project_type_menu() {
    # Parse arguments: first argument might be default selection, rest are options
    local default_selected=0
    local recommended_index=-1
    local -a options=()

    # Check if first argument is a number (default selection)
    if [[ $1 =~ ^[0-9]+$ ]]; then
        default_selected=$1
        recommended_index=$1
        shift
    fi

    options=("$@")
    local selected=$default_selected
    local num_options=${#options[@]}

    # Ensure selected is within bounds
    if [[ $selected -ge $num_options ]]; then
        selected=$((num_options - 1))
    fi

    # Check if terminal supports interactive features
    if [[ ! -t 0 ]] || [[ "${NON_INTERACTIVE:-false}" == "true" ]]; then
        # Fallback to numbered list for non-interactive mode
        echo ""
        echo -e "${CYAN}Project Types:${NC}"
        for i in "${!options[@]}"; do
            echo "$((i+1)). ${options[$i]}"
        done
        return 0
    fi

    # Save original terminal settings
    local original_settings
    original_settings=$(stty -g 2>/dev/null || echo "")

    # Hide cursor and enable raw mode
    tput civis 2>/dev/null || true
    stty -echo -icanon min 1 time 0 2>/dev/null || true

    cleanup_menu() {
        # Restore cursor and normal mode
        tput cnorm 2>/dev/null || true
        if [[ -n "$original_settings" ]]; then
            stty "$original_settings" 2>/dev/null || true
        else
            stty echo icanon 2>/dev/null || true
        fi
    }
    trap cleanup_menu EXIT

    while true; do
        # Clear and redraw menu
        echo -e "\033[2J\033[H" # Clear screen and move to top
        echo -e "${CYAN}Project Types (Use ↑↓ arrows, Enter to select):${NC}"
        echo ""

        for i in "${!options[@]}"; do
            local prefix="  "
            local option_text="$((i+1)). ${options[$i]}"

            if [[ $i -eq $selected ]]; then
                if [[ $i -eq $recommended_index ]]; then
                    echo -e "  ${GREEN}► 🎯 $option_text (Recommended)${NC}"
                else
                    echo -e "  ${GREEN}► $option_text${NC}"
                fi
            else
                if [[ $i -eq $recommended_index ]]; then
                    echo -e "    ${BLUE}🎯 $option_text (Recommended)${NC}"
                else
                    echo "    $option_text"
                fi
            fi
        done

        echo ""
        echo -e "${YELLOW}Use ↑/↓ arrows to navigate, Enter to select, 'q' to quit${NC}"

        # Read single character
        IFS= read -r -s -n1 char

        case "$char" in
            $'\x1b') # ESC sequence
                read -r -s -n2 char
                case "$char" in
                    '[A') # Up arrow
                        if [[ $selected -gt 0 ]]; then
                            ((selected--))
                        fi
                        ;;
                    '[B') # Down arrow
                        if [[ $selected -lt $((num_options - 1)) ]]; then
                            ((selected++))
                        fi
                        ;;
                esac
                ;;
            '') # Enter
                cleanup_menu
                trap - EXIT
                echo "" # Clear line after selection
                MENU_SELECTION=$selected
                return 0
                ;;
            'q'|'Q') # Quit
                cleanup_menu
                trap - EXIT
                echo ""
                echo -e "${YELLOW}Setup cancelled by user${NC}"
                exit 0
                ;;
        esac
    done
}

# Interactive menu with arrow key navigation (for complex menus)
show_interactive_menu() {
    # New signature: claude_suggestion, question_title, options...
    local claude_suggestion="$1"
    local question_title="$2"
    shift 2
    local -a options=("$@")
    local selected=0
    local recommended_index=-1  # No specific recommendation for generic menus
    local num_options=${#options[@]}

    # Ensure selected is within bounds
    if [[ $selected -ge $num_options ]]; then
        selected=$((num_options - 1))
    fi

    # Check if terminal supports interactive features
    if [[ ! -t 0 ]] || [[ "${NON_INTERACTIVE:-false}" == "true" ]]; then
        # Fallback to numbered list for non-interactive mode
        echo ""
        echo -e "${CYAN}Project Types:${NC}"
        for i in "${!options[@]}"; do
            echo "$((i+1)). ${options[$i]}"
        done
        return 0
    fi

    # Save original terminal settings
    local original_settings
    original_settings=$(stty -g 2>/dev/null || echo "")

    # Hide cursor and enable raw mode
    tput civis 2>/dev/null || true
    stty -echo -icanon min 1 time 0 2>/dev/null || true

    cleanup_menu() {
        # Restore cursor and normal mode
        tput cnorm 2>/dev/null || true
        if [[ -n "$original_settings" ]]; then
            stty "$original_settings" 2>/dev/null || true
        else
            stty echo icanon 2>/dev/null || true
        fi
    }
    trap cleanup_menu EXIT

    while true; do
        # Clear and redraw menu
        echo -e "\033[2J\033[H" # Clear screen and move to top

        # Show question title
        echo -e "${CYAN}$question_title${NC}"
        echo ""

        # Show Claude suggestion if available
        if [[ -n "$claude_suggestion" ]]; then
            echo -e "${CYAN}🤖 Claude suggests: $claude_suggestion${NC}"
            echo ""
        fi

        echo -e "${YELLOW}Use ↑↓ arrows, Enter to select:${NC}"
        echo ""

        for i in "${!options[@]}"; do
            local prefix="  "
            local option_text="$((i+1)). ${options[$i]}"

            if [[ $i -eq $selected ]]; then
                if [[ $i -eq $recommended_index ]]; then
                    echo -e "  ${GREEN}► 🎯 $option_text (Recommended)${NC}"
                else
                    echo -e "  ${GREEN}► $option_text${NC}"
                fi
            else
                if [[ $i -eq $recommended_index ]]; then
                    echo -e "    ${BLUE}🎯 $option_text (Recommended)${NC}"
                else
                    echo "    $option_text"
                fi
            fi
        done

        echo ""
        if [[ -n "$claude_suggestion" ]]; then
            echo -e "${BLUE}Press 's' to use Claude suggestion directly${NC}"
        fi
        echo -e "${YELLOW}Use ↑/↓ arrows to navigate, Enter to select, 'q' to quit${NC}"

        # Read single character
        IFS= read -r -s -n1 char

        case "$char" in
            $'\x1b') # ESC sequence
                read -r -s -n2 char
                case "$char" in
                    '[A') # Up arrow
                        if [[ $selected -gt 0 ]]; then
                            ((selected--))
                        fi
                        ;;
                    '[B') # Down arrow
                        if [[ $selected -lt $((num_options - 1)) ]]; then
                            ((selected++))
                        fi
                        ;;
                esac
                ;;
            '') # Enter
                cleanup_menu
                trap - EXIT
                echo "" # Clear line after selection
                MENU_SELECTION=$selected
                return 0
                ;;
            's'|'S') # Use Claude suggestion
                if [[ -n "$claude_suggestion" ]]; then
                    cleanup_menu
                    trap - EXIT
                    echo ""
                    # Return special code to indicate suggestion was used
                    MENU_SELECTION=-1
                    CLAUDE_SUGGESTION_USED="$claude_suggestion"
                    return 0
                fi
                ;;
            'q'|'Q') # Quit
                cleanup_menu
                trap - EXIT
                echo ""
                echo -e "${YELLOW}Setup cancelled by user${NC}"
                exit 0
                ;;
        esac
    done
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

    # Run stack detection for intelligent project type suggestions
    local detected_stack_info=""
    local contribute_analysis=""

    # Load stack detector if not already loaded
    if ! declare -f detect_project_stack > /dev/null; then
        if [[ -f "$SCRIPT_DIR/stack-detector.sh" ]]; then
            source "$SCRIPT_DIR/stack-detector.sh"
        fi
    fi

    if declare -f detect_project_stack > /dev/null; then
        echo -e "${CYAN}🔍 Analyzing project structure...${NC}"
        detected_stack_info=$(detect_project_stack "$PROJECT_DIR" 2>/dev/null || echo "")

        # If no stack detected, try to analyze files manually and offer Claude-based contribution
        if [[ -z "$detected_stack_info" ]]; then
            echo -e "${CYAN}🔍 Analyzing project files for unknown project type...${NC}"

            # Do basic file analysis to suggest a project type
            local suggested_type="other"
            local suggested_tech="Unknown Project"
            local confidence=50

            # Check for common Kotlin Multiplatform patterns
            if [[ -f "$PROJECT_DIR/build.gradle.kts" ]] && [[ -f "$PROJECT_DIR/settings.gradle.kts" ]]; then
                if [[ -d "$PROJECT_DIR/composeApp" ]] || [[ -d "$PROJECT_DIR/shared" ]] || [[ -d "$PROJECT_DIR/iosApp" ]]; then
                    suggested_type="kotlin-multiplatform-mobile"
                    suggested_tech="Kotlin/Compose Multiplatform"
                    confidence=85
                    echo -e "${GREEN}📱 Detected Kotlin Multiplatform Mobile project${NC}"
                fi
            # Check for Flutter
            elif [[ -f "$PROJECT_DIR/pubspec.yaml" ]] && [[ -d "$PROJECT_DIR/lib" ]]; then
                suggested_type="flutter-app"
                suggested_tech="Flutter"
                confidence=90
                echo -e "${GREEN}📱 Detected Flutter project${NC}"
            # Check for React Native
            elif [[ -f "$PROJECT_DIR/package.json" ]] && [[ -d "$PROJECT_DIR/android" ]] && [[ -d "$PROJECT_DIR/ios" ]]; then
                suggested_type="react-native-app"
                suggested_tech="React Native"
                confidence=90
                echo -e "${GREEN}📱 Detected React Native project${NC}"
            # Check for Go projects
            elif [[ -f "$PROJECT_DIR/go.mod" ]]; then
                suggested_type="go-app"
                suggested_tech="Go"
                confidence=85
                echo -e "${GREEN}🐹 Detected Go project${NC}"
            # Check for Rust projects
            elif [[ -f "$PROJECT_DIR/Cargo.toml" ]]; then
                suggested_type="rust-app"
                suggested_tech="Rust"
                confidence=85
                echo -e "${GREEN}🦀 Detected Rust project${NC}"
            fi

            # If we found a suggestion, use it
            if [[ "$suggested_type" != "other" ]]; then
                detected_stack_info="$suggested_type|$suggested_tech|$suggested_type|$confidence"
                echo -e "${BLUE}💡 Will offer this as a custom project type option${NC}"
            else
                echo -e "${YELLOW}⚠️  Could not determine project type from file structure${NC}"
            fi
        fi
    fi

    # Project type with intelligent detection
    local suggested_option=""
    local suggested_description=""
    local detected_type=""
    local custom_type_available=false
    local max_option=8

    if [[ -n "$detected_stack_info" ]]; then
        IFS='|' read -r _ _ detected_type _ <<< "$detected_stack_info"
        suggested_option=$(map_detected_project_type "$detected_type")
        suggested_description=$(get_project_type_description "$detected_type")

        # Check if we need to offer a custom option
        if [[ "$suggested_option" == "8" ]] && [[ "$detected_type" != "other" ]]; then
            custom_type_available=true
            max_option=9
        fi
    fi

    # Prepare menu options
    local -a menu_options=(
        "Web Application (Frontend + Backend)"
        "Mobile Application"
        "Backend API Service"
        "Desktop Application"
        "CLI Tool/Utility"
        "Library/Package"
        "Data Science/ML Project"
        "Other"
    )

    # Add custom option if detected
    if [[ "$custom_type_available" == "true" ]]; then
        menu_options+=("Create new project type: $suggested_description")
    fi

    # Show intelligent suggestion if available
    if [[ -n "$suggested_option" ]] && [[ "$suggested_option" != "8" ]]; then
        echo -e "${GREEN}🎯 Recommended: $suggested_option ($suggested_description)${NC}"
    elif [[ "$custom_type_available" == "true" ]]; then
        echo -e "${GREEN}🎯 Recommended: 9 (Create new: $suggested_description)${NC}"
        echo -e "${CYAN}💡 This project type was automatically detected for you${NC}"
        suggested_option="9"
    fi

    # Get user choice
    if [[ "${NON_INTERACTIVE:-false}" == "true" ]]; then
        PROJECT_TYPE_NUM="${suggested_option:-1}"
        echo "Select project type (1-$max_option) [$PROJECT_TYPE_NUM]: $PROJECT_TYPE_NUM (non-interactive mode)"
    else
        # Check if terminal supports interactive features
        if [[ -t 0 ]] && command -v tput >/dev/null 2>&1; then
            echo ""
            echo -e "${BLUE}Choose project type:${NC}"

            # Use interactive menu with suggested default
            local default_index=0
            if [[ -n "$suggested_option" ]]; then
                default_index=$((suggested_option - 1)) # Convert 1-based to 0-based
            fi

            if show_project_type_menu "$default_index" "${menu_options[@]}"; then
                PROJECT_TYPE_NUM=$((MENU_SELECTION + 1)) # Convert 0-based to 1-based
            else
                # Fallback if interactive menu fails
                echo ""
                for i in "${!menu_options[@]}"; do
                    echo "$((i+1)). ${menu_options[$i]}"
                done
                local default_choice="${suggested_option:-1}"
                read -r -p "Select project type (1-$max_option) [$default_choice]: " PROJECT_TYPE_NUM || {
                    echo -e "\n\033[1;33m⚠️  Input interrupted by user.\033[0m"
                    exit 130
                }
            fi
        else
            # Fallback for terminals without interactive support
            echo ""
            echo -e "${CYAN}Project Types:${NC}"
            for i in "${!menu_options[@]}"; do
                echo "$((i+1)). ${menu_options[$i]}"
            done
            local default_choice="${suggested_option:-1}"
            read -r -p "Select project type (1-$max_option) [$default_choice]: " PROJECT_TYPE_NUM || {
                echo -e "\n\033[1;33m⚠️  Input interrupted by user.\033[0m"
                exit 130
            }
        fi
    fi
    PROJECT_TYPE_NUM=${PROJECT_TYPE_NUM:-${suggested_option:-1}}

    # Handle project type selection
    case $PROJECT_TYPE_NUM in
        1) PROJECT_TYPE="web-app" ;;
        2) PROJECT_TYPE="mobile-app" ;;
        3) PROJECT_TYPE="backend-service" ;;
        4) PROJECT_TYPE="desktop-app" ;;
        5) PROJECT_TYPE="cli-tool" ;;
        6) PROJECT_TYPE="library" ;;
        7) PROJECT_TYPE="data-science" ;;
        8) PROJECT_TYPE="other" ;;
        9)
            if [[ "$custom_type_available" == "true" ]]; then
                PROJECT_TYPE="$detected_type"
                DETECTED_CUSTOM_TYPE="$detected_type"
                echo -e "${GREEN}✅ Selected new project type: $suggested_description${NC}"
                echo -e "${CYAN}💡 This will be offered for contribution at the end of setup${NC}"
            else
                PROJECT_TYPE="other"
            fi
            ;;
        *) PROJECT_TYPE="other" ;;
    esac
}

# Get security information
get_security_info() {
    echo ""
    echo -e "${BLUE}🔐 Security & Compliance${NC}"
    echo "=============================="

    # Critical assets - use working interactive menu pattern
    local claude_suggestion=""
    if [[ -f "$CLAUDE_SUGGESTIONS_FILE" ]]; then
        claude_suggestion=$(grep "CRITICAL_ASSETS_SUGGESTION:" "$CLAUDE_SUGGESTIONS_FILE" 2>/dev/null | cut -d: -f2- | xargs || echo "")
    fi

    local -a critical_assets_options=(
        "User data (PII, passwords, emails)"
        "Payment information"
        "API keys and secrets"
        "Configuration files"
        "Database credentials"
        "Source code"
        "Business logic"
        "Custom/Other"
    )

    if [[ "${NON_INTERACTIVE:-false}" == "true" ]]; then
        CRITICAL_ASSETS="$claude_suggestion"
        echo "Critical assets: $CRITICAL_ASSETS (non-interactive mode)"
    else
        if show_interactive_menu "$claude_suggestion" "What are your critical assets?" "${critical_assets_options[@]}"; then
            local selected_index=$MENU_SELECTION
            if [[ $selected_index -eq -1 ]]; then
                # Claude suggestion was used
                CRITICAL_ASSETS="$CLAUDE_SUGGESTION_USED"
            elif [[ $selected_index -eq $((${#critical_assets_options[@]} - 1)) ]]; then
                # Custom option selected
                read -r -p "Enter custom critical assets: " CRITICAL_ASSETS
            else
                CRITICAL_ASSETS="${critical_assets_options[$selected_index]}"
            fi
        else
            # Fallback if interactive menu fails
            CRITICAL_ASSETS=$(read_with_suggestion "Critical assets: " "$claude_suggestion")
        fi
    fi
    CRITICAL_ASSETS=${CRITICAL_ASSETS:-"user data"}

    # Compliance requirements
    local compliance_suggestion=""
    if [[ -f "$CLAUDE_SUGGESTIONS_FILE" ]]; then
        compliance_suggestion=$(grep "COMPLIANCE_SUGGESTION:" "$CLAUDE_SUGGESTIONS_FILE" 2>/dev/null | cut -d: -f2- | xargs || echo "")
    fi

    local -a compliance_options=(
        "GDPR (EU data protection)"
        "HIPAA (Healthcare)"
        "PCI DSS (Payment processing)"
        "SOX (Financial reporting)"
        "ISO 27001 (Information security)"
        "Internal company policies"
        "No specific compliance"
        "Custom/Other"
    )

    if [[ "${NON_INTERACTIVE:-false}" == "true" ]]; then
        COMPLIANCE="$compliance_suggestion"
        echo "Compliance requirements: $COMPLIANCE (non-interactive mode)"
    else
        if show_interactive_menu "$compliance_suggestion" "What compliance requirements apply?" "${compliance_options[@]}"; then
            local selected_index=$MENU_SELECTION
            if [[ $selected_index -eq -1 ]]; then
                # Claude suggestion was used
                COMPLIANCE="$CLAUDE_SUGGESTION_USED"
            elif [[ $selected_index -eq $((${#compliance_options[@]} - 1)) ]]; then
                # Custom option selected
                read -r -p "Enter custom compliance requirement: " COMPLIANCE
            else
                COMPLIANCE="${compliance_options[$selected_index]}"
            fi
        else
            # Fallback if interactive menu fails
            COMPLIANCE=$(read_with_suggestion "Compliance requirements (1-8) [7]: " "$compliance_suggestion")
        fi
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

    local -a tech_stack_options=(
        "React + Node.js + PostgreSQL"
        "Vue.js + Express + MongoDB"
        "Python Django + PostgreSQL"
        "Python FastAPI + SQLAlchemy"
        "Java Spring Boot + MySQL"
        "Go + PostgreSQL"
        "Ruby on Rails + PostgreSQL"
        "PHP Laravel + MySQL"
        "ASP.NET Core + SQL Server"
        "Flutter + Firebase"
        "React Native + Node.js"
        "Custom/Other"
    )

    if [[ "${NON_INTERACTIVE:-false}" == "true" ]]; then
        TECH_STACK="$claude_suggestion"
        echo "Tech stack: $TECH_STACK (non-interactive mode)"
    else
        if show_interactive_menu "$claude_suggestion" "What is your tech stack?" "${tech_stack_options[@]}"; then
            local selected_index=$MENU_SELECTION
            if [[ $selected_index -eq -1 ]]; then
                # Claude suggestion was used
                TECH_STACK="$CLAUDE_SUGGESTION_USED"
            elif [[ $selected_index -eq $((${#tech_stack_options[@]} - 1)) ]]; then
                # Custom option selected
                read -r -p "Enter custom tech stack: " TECH_STACK
            else
                TECH_STACK="${tech_stack_options[$selected_index]}"
            fi
        else
            # Fallback if interactive menu fails
            TECH_STACK=$(read_with_suggestion "Tech stack: " "$claude_suggestion")
        fi
    fi

    # Common issues
    local issues_suggestion=""
    if [[ -f "$CLAUDE_SUGGESTIONS_FILE" ]]; then
        issues_suggestion=$(grep "COMMON_ISSUES_SUGGESTION:" "$CLAUDE_SUGGESTIONS_FILE" 2>/dev/null | cut -d: -f2- | xargs || echo "")
    fi

    local -a issues_options=(
        "Authentication and authorization"
        "Input validation and sanitization"
        "Database performance"
        "API rate limiting"
        "Memory leaks"
        "Security vulnerabilities"
        "Error handling"
        "Data consistency"
        "Scalability issues"
        "Testing coverage"
        "Deployment issues"
        "Configuration management"
        "Custom/Other"
    )

    if [[ "${NON_INTERACTIVE:-false}" == "true" ]]; then
        COMMON_ISSUES="$issues_suggestion"
        echo "Common issues: $COMMON_ISSUES (non-interactive mode)"
    else
        if show_interactive_menu "$issues_suggestion" "What are common issues you want to address?" "${issues_options[@]}"; then
            local selected_index=$MENU_SELECTION
            if [[ $selected_index -eq -1 ]]; then
                # Claude suggestion was used
                COMMON_ISSUES="$CLAUDE_SUGGESTION_USED"
            elif [[ $selected_index -eq $((${#issues_options[@]} - 1)) ]]; then
                # Custom option selected
                read -r -p "Enter custom common issues: " COMMON_ISSUES
            else
                COMMON_ISSUES="${issues_options[$selected_index]}"
            fi
        else
            # Fallback if interactive menu fails
            COMMON_ISSUES=$(read_with_suggestion "Common issues: " "$issues_suggestion")
        fi
    fi
    COMMON_ISSUES=${COMMON_ISSUES:-"authentication, input validation"}
}