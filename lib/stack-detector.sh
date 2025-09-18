#!/bin/bash
# Modular Stack Detection System
# Loads and executes individual stack detection modules

# Get the directory of this script (lib directory)
STACK_DETECTOR_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STACKS_DIR="$(dirname "$STACK_DETECTOR_DIR")/stacks"

# Load all stack detection modules
load_stack_modules() {
    if [[ -d "$STACKS_DIR" ]]; then
        for stack_file in "$STACKS_DIR"/*.sh; do
            if [[ -f "$stack_file" ]]; then
                source "$stack_file"
            fi
        done
    fi
}

# Detect project stack using modular detection
detect_project_stack() {
    local project_dir="$1"
    local best_match=""
    local best_confidence=0
    local best_tech_stack=""
    local best_project_type=""
    local detection_results=()

    # Load all detection modules
    load_stack_modules

    # Try all known detection functions (expandable list)
    local detection_functions=(
        "detect_nextjs_ai"
        "detect_python_ai"
        "detect_cordova"
        "detect_bash_cli"
    )

    for func in "${detection_functions[@]}"; do
        if declare -f "$func" > /dev/null; then
            local result
            if result=$("$func" "$project_dir" 2>/dev/null); then
                local stack_id tech_stack project_type confidence
                IFS='|' read -r stack_id tech_stack project_type confidence <<< "$result"

                detection_results+=("$stack_id:$confidence:$tech_stack:$project_type")

                if [[ $confidence -gt $best_confidence ]]; then
                    best_match="$stack_id"
                    best_confidence="$confidence"
                    best_tech_stack="$tech_stack"
                    best_project_type="$project_type"
                fi
            fi
        fi
    done

    # Return best match if confidence is high enough
    if [[ $best_confidence -ge 50 ]]; then
        echo "$best_match|$best_tech_stack|$best_project_type|$best_confidence"
        return 0
    fi

    return 1
}

# Get patterns for detected stack
get_stack_patterns() {
    local stack_id="$1"
    load_stack_modules

    case "$stack_id" in
        "nextjs-ai")
            get_nextjs_ai_patterns
            ;;
        "python-ai")
            get_python_ai_patterns
            ;;
        "cordova")
            get_cordova_patterns
            ;;
        "bash-cli")
            get_bash_cli_patterns
            ;;
        *)
            echo "# No specific patterns available for $stack_id"
            ;;
    esac
}

# Get critical assets for detected stack
get_stack_assets() {
    local stack_id="$1"
    load_stack_modules

    case "$stack_id" in
        "nextjs-ai")
            get_nextjs_ai_assets
            ;;
        "python-ai")
            get_python_ai_assets
            ;;
        "cordova")
            get_cordova_assets
            ;;
        "bash-cli")
            get_bash_cli_assets
            ;;
        *)
            echo "user data, application configurations"
            ;;
    esac
}

# Get mandatory requirements for detected stack
get_stack_requirements() {
    local stack_id="$1"
    load_stack_modules

    case "$stack_id" in
        "nextjs-ai")
            get_nextjs_ai_requirements
            ;;
        "python-ai")
            get_python_ai_requirements
            ;;
        "cordova")
            get_cordova_requirements
            ;;
        "bash-cli")
            get_bash_cli_requirements
            ;;
        *)
            echo "None"
            ;;
    esac
}

# Get common issues for detected stack
get_stack_issues() {
    local stack_id="$1"
    load_stack_modules

    case "$stack_id" in
        "nextjs-ai")
            get_nextjs_ai_issues
            ;;
        "python-ai")
            get_python_ai_issues
            ;;
        "cordova")
            get_cordova_issues
            ;;
        "bash-cli")
            get_bash_cli_issues
            ;;
        *)
            echo "dependency conflicts, performance issues"
            ;;
    esac
}

# Check if this is a new/unknown stack that could benefit claude-ally
analyze_unknown_stack() {
    local project_dir="$1"
    local project_name="$2"

    # Try modular detection first
    if detect_project_stack "$project_dir" > /dev/null; then
        return 1  # Known stack, no contribution needed
    fi

    # Check for interesting but unrecognized patterns
    local interesting_files=()
    local interesting_deps=()

    # Look for framework files that might be new/uncommon
    local framework_files=(
        "package.json" "requirements.txt" "Cargo.toml" "go.mod" "composer.json"
        "pom.xml" "build.gradle" "CMakeLists.txt" "Makefile" "pubspec.yaml"
        "mix.exs" "Gemfile" "setup.py" "pyproject.toml"
    )

    for file in "${framework_files[@]}"; do
        if [[ -f "$project_dir/$file" ]]; then
            interesting_files+=("$file")
        fi
    done

    # Analyze package.json for new frameworks
    if [[ -f "$project_dir/package.json" ]]; then
        # Extract potential new frameworks (not in our current detection)
        local new_frameworks=$(grep -o '"[^"]*":\s*"[^"]*"' "$project_dir/package.json" | head -20)
        interesting_deps+=("$new_frameworks")
    fi

    # If we found interesting patterns but no detection, suggest contribution
    if [[ ${#interesting_files[@]} -gt 0 ]]; then
        echo "unknown|${interesting_files[*]}|potential-contribution|30"
        return 0
    fi

    return 1
}

# Trigger test
