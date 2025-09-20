#!/bin/bash
# Stack detection for Bash CLI Tools
# Detects shell-based command-line interface tools and utilities

detect_bash_cli() {
    local project_dir="$1"
    local confidence=0
    local features=()
    local project_type="cli-tool"

    # Check for main executable shell scripts
    if [[ -f "$project_dir/claude-ally.sh" ]] || [[ -f "$project_dir/main.sh" ]] || [[ -f "$project_dir/cli.sh" ]]; then
        confidence=$((confidence + 30))
        features+=("Main CLI script")
    fi

    # Check for multiple executable shell scripts (indicates CLI tool)
    local shell_scripts
    shell_scripts=$(find "$project_dir" -maxdepth 1 -name "*.sh" -type f -exec test -x {} \; -print | wc -l)
    if [[ $shell_scripts -ge 3 ]]; then
        confidence=$((confidence + 25))
        features+=("Multiple shell scripts")
    fi

    # Check for CLI-specific patterns
    if [[ -f "$project_dir/setup.sh" ]] || [[ -f "$project_dir/install.sh" ]]; then
        confidence=$((confidence + 20))
        features+=("Setup/Install script")
    fi

    # Check for test directory
    if [[ -d "$project_dir/tests" ]]; then
        confidence=$((confidence + 15))
        features+=("Test suite")
    fi

    # Check for GitHub Actions workflows
    if [[ -d "$project_dir/.github/workflows" ]]; then
        confidence=$((confidence + 10))
        features+=("CI/CD Pipeline")
    fi

    # Check for README with CLI usage patterns
    if [[ -f "$project_dir/README.md" ]]; then
        if grep -q -E "(command|CLI|Usage:|Options:|--help)" "$project_dir/README.md" 2>/dev/null; then
            confidence=$((confidence + 15))
            features+=("CLI Documentation")
        fi
    fi

    # Check for help/usage functions in scripts
    if find "$project_dir" -name "*.sh" -exec grep -l -E "(show_help|usage|--help|\-h)" {} \; | head -1 >/dev/null 2>&1; then
        confidence=$((confidence + 10))
        features+=("Help system")
    fi

    # Check for configuration management
    if [[ -f "$project_dir/config-manager.sh" ]] || [[ -f "$project_dir/config.sh" ]]; then
        confidence=$((confidence + 10))
        features+=("Configuration management")
    fi

    # Check for modular architecture
    if [[ -d "$project_dir/modules" ]] || [[ -d "$project_dir/lib" ]] || [[ -d "$project_dir/stacks" ]]; then
        confidence=$((confidence + 15))
        features+=("Modular architecture")
    fi

    # Minimum confidence check
    if [[ $confidence -lt 50 ]]; then
        return 1
    fi

    # Build tech stack description
    local tech_stack="Bash/Shell CLI Tool"

    # Add specific features
    if [[ " ${features[*]} " =~ " Modular architecture " ]]; then
        tech_stack="$tech_stack, Modular"
    fi

    if [[ " ${features[*]} " =~ " Test suite " ]]; then
        tech_stack="$tech_stack, Tested"
    fi

    if [[ " ${features[*]} " =~ " CI/CD Pipeline " ]]; then
        tech_stack="$tech_stack, CI/CD"
    fi

    if [[ " ${features[*]} " =~ " Configuration management " ]]; then
        tech_stack="$tech_stack, Configurable"
    fi

    # Return detection result
    echo "bash-cli|$tech_stack|$project_type|$confidence"
    return 0
}

# Get patterns for bash CLI projects
get_bash_cli_patterns() {
    cat << 'EOF'
# Claude Programming Assistant Patterns for Bash CLI Tools

## Code Structure Patterns
- **Modular Design**: Break functionality into separate shell scripts
- **Error Handling**: Implement comprehensive error trapping and validation
- **Configuration Management**: Use config files for user preferences
- **Help System**: Provide detailed usage and help information

## Security Patterns
- **Input Validation**: Sanitize all user inputs and file paths
- **Permission Checks**: Verify file permissions before operations
- **Secure Temp Files**: Use proper temporary file creation
- **No Secret Exposure**: Never log or display sensitive information

## Testing Patterns
- **Unit Testing**: Test individual functions with bash test frameworks
- **Integration Testing**: Test CLI commands and workflows
- **Cross-Platform Testing**: Ensure compatibility across OS platforms
- **Continuous Integration**: Automated testing with GitHub Actions
EOF
}

# Get critical assets for bash CLI projects
get_bash_cli_assets() {
    echo "shell scripts, configuration files, test suites, user data, CLI binaries"
}

# Get mandatory requirements for bash CLI projects
get_bash_cli_requirements() {
    cat << 'EOF'
- Bash 4.0+ compatibility for cross-platform support
- Proper error handling and exit codes
- Input validation and sanitization
- Help/usage documentation for all commands
- Executable permissions on all shell scripts
- Cross-platform compatibility (Linux/macOS/Windows Git Bash)
EOF
}

# Get common issues for bash CLI projects
get_bash_cli_issues() {
    cat << 'EOF'
- Shell compatibility issues between bash versions
- File permission problems on different platforms
- Path handling issues (spaces, special characters)
- Error handling and proper exit codes
- Performance issues with large datasets
- Security vulnerabilities in input handling
- Cross-platform compatibility challenges
EOF
}

# Export all functions
if [[ "${BASH_SOURCE[0]}" != "${0}" ]]; then
    export -f detect_bash_cli
    export -f get_bash_cli_patterns
    export -f get_bash_cli_assets
    export -f get_bash_cli_requirements
    export -f get_bash_cli_issues
fi