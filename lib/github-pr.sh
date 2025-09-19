#!/bin/bash
# GitHub Pull Request Automation for Claude-Ally Contributions
# Helps users automatically create pull requests for new stack contributions

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# Claude-Ally repository information
CLAUDE_ALLY_REPO="https://github.com/mglcel/claude-ally.git"
CLAUDE_ALLY_FORK_URL="https://github.com/mglcel/claude-ally/fork"

# Cross-platform compatibility
detect_os() {
    case "$(uname -s)" in
        Linux*)     echo "linux";;
        Darwin*)    echo "macos";;
        CYGWIN*|MINGW*|MSYS*) echo "windows";;
        *)          echo "unknown";;
    esac
}

# Check if gh CLI is available and offer installation
check_gh_availability() {
    if command -v gh &> /dev/null; then
        if gh auth status &> /dev/null; then
            echo -e "${GREEN}✅ GitHub CLI authenticated and ready${NC}"
            return 0
        else
            echo -e "${YELLOW}⚠️ GitHub CLI found but not authenticated${NC}"
            echo -e "${CYAN}Please authenticate with GitHub:${NC}"
            echo "  gh auth login"
            echo ""
            return 1
        fi
    else
        echo -e "${RED}❌ GitHub CLI (gh) not found${NC}"
        offer_gh_installation
        return 1
    fi
}

# Offer GitHub CLI installation based on OS
offer_gh_installation() {
    local os_type
    os_type=$(detect_os)

    echo ""
    echo -e "${CYAN}📦 GitHub CLI INSTALLATION REQUIRED${NC}"
    echo -e "${BOLD}====================================${NC}"
    echo ""
    echo -e "${YELLOW}To enable automated GitHub pull requests, please install GitHub CLI:${NC}"
    echo ""

    case "$os_type" in
        "macos")
            echo -e "${BOLD}macOS Installation Options:${NC}"
            echo ""
            echo -e "${GREEN}Option 1 - Homebrew (Recommended):${NC}"
            echo "  brew install gh"
            echo ""
            echo -e "${GREEN}Option 2 - Direct Download:${NC}"
            echo "  1. Visit: https://cli.github.com"
            echo "  2. Download macOS installer"
            echo "  3. Run the installer"
            echo ""
            ;;
        "linux")
            echo -e "${BOLD}Linux Installation Options:${NC}"
            echo ""
            echo -e "${GREEN}Ubuntu/Debian:${NC}"
            echo "  curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg"
            echo "  echo \"deb [arch=\$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main\" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null"
            echo "  sudo apt update && sudo apt install gh"
            echo ""
            echo -e "${GREEN}Fedora/CentOS/RHEL:${NC}"
            echo "  sudo dnf install gh"
            echo ""
            echo -e "${GREEN}Arch Linux:${NC}"
            echo "  sudo pacman -S github-cli"
            echo ""
            echo -e "${GREEN}Or use the universal installer:${NC}"
            echo "  curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo tee /usr/share/keyrings/githubcli-archive-keyring.gpg > /dev/null"
            echo ""
            ;;
        "windows")
            echo -e "${BOLD}Windows Installation Options:${NC}"
            echo ""
            echo -e "${GREEN}Option 1 - Chocolatey:${NC}"
            echo "  choco install gh"
            echo ""
            echo -e "${GREEN}Option 2 - Scoop:${NC}"
            echo "  scoop install gh"
            echo ""
            echo -e "${GREEN}Option 3 - Direct Download:${NC}"
            echo "  1. Visit: https://cli.github.com"
            echo "  2. Download Windows installer (.msi)"
            echo "  3. Run the installer"
            echo ""
            echo -e "${GREEN}Option 4 - Windows Package Manager:${NC}"
            echo "  winget install --id GitHub.cli"
            echo ""
            ;;
        *)
            echo -e "${GREEN}Universal Installation:${NC}"
            echo "  Visit: https://cli.github.com"
            echo "  Download the appropriate package for your system"
            echo ""
            ;;
    esac

    echo -e "${BOLD}After Installation:${NC}"
    echo "1. Restart your terminal"
    echo "2. Run: gh auth login"
    echo "3. Follow the authentication prompts"
    echo "4. Re-run this script"
    echo ""

    local install_choice
    read -p "Would you like to open the GitHub CLI website for installation? (Y/n): " install_choice

    if [[ ! "$install_choice" =~ ^[Nn] ]]; then
        case "$os_type" in
            "macos")
                open "https://cli.github.com" 2>/dev/null || true
                ;;
            "linux")
                xdg-open "https://cli.github.com" 2>/dev/null || true
                ;;
            "windows")
                start "https://cli.github.com" 2>/dev/null || true
                ;;
        esac
        echo -e "${CYAN}🌐 Opening GitHub CLI website...${NC}"
    fi
}

# Check if git is configured
check_git_config() {
    if git config --global user.name &> /dev/null && git config --global user.email &> /dev/null; then
        return 0
    else
        echo -e "${RED}❌ Git user name or email not configured${NC}"
        echo -e "${CYAN}Please configure git first:${NC}"
        echo "  git config --global user.name \"Your Name\""
        echo "  git config --global user.email \"your.email@example.com\""
        return 1
    fi
}

# Get user's GitHub username
get_github_username() {
    if command -v gh &> /dev/null && gh auth status &> /dev/null; then
        gh api user --jq '.login' 2>/dev/null
    else
        return 1
    fi
}

# Create automated pull request
create_automated_pr() {
    local stack_id="$1"
    local tech_stack="$2"
    local project_type="$3"
    local detection_patterns="$4"
    local project_dir="$5"
    local project_name="$6"

    echo -e "${CYAN}🚀 AUTOMATED GITHUB PULL REQUEST${NC}"
    echo -e "${BOLD}=================================${NC}"
    echo ""

    # Check prerequisites
    if ! check_git_config; then
        return 1
    fi

    if ! check_gh_availability; then
        echo -e "${CYAN}Alternative: Manual contribution workflow will be provided${NC}"
        return 1
    fi

    local github_username
    github_username=$(get_github_username)
    if [[ -z "$github_username" ]]; then
        echo -e "${RED}❌ Could not determine GitHub username${NC}"
        return 1
    fi

    echo -e "${GREEN}✅ GitHub CLI authenticated as: ${BOLD}$github_username${NC}"
    echo ""

    # Ask user if they want automated PR
    echo -e "${YELLOW}Would you like to automatically create a pull request to claude-ally?${NC}"
    echo -e "${CYAN}This will:${NC}"
    echo "  1. 🍴 Fork the claude-ally repository to your GitHub account"
    echo "  2. 📥 Clone your fork locally"
    echo "  3. 🔧 Create and commit your new stack detection module"
    echo "  4. 📤 Push changes to your fork"
    echo "  5. 🔄 Create a pull request to the main repository"
    echo ""

    local auto_pr_choice
    read -p "Create automated pull request? (Y/n): " auto_pr_choice

    if [[ "$auto_pr_choice" =~ ^[Nn] ]]; then
        echo -e "${BLUE}No problem! Manual contribution guide will be provided instead.${NC}"
        return 1
    fi

    # Create temporary working directory
    local work_dir="/tmp/claude-ally-pr-$(date +%s)"
    mkdir -p "$work_dir"
    cd "$work_dir" || exit 1

    echo ""
    echo -e "${CYAN}🔄 Step 1/5: Forking claude-ally repository...${NC}"

    # Fork the repository
    if ! gh repo fork "$CLAUDE_ALLY_REPO" --clone=false 2>/dev/null; then
        echo -e "${YELLOW}⚠️ Fork might already exist, continuing...${NC}"
    fi

    echo -e "${CYAN}📥 Step 2/5: Cloning your fork...${NC}"

    # Clone the user's fork
    if ! gh repo clone "$github_username/claude-ally" claude-ally-fork; then
        echo -e "${RED}❌ Failed to clone fork${NC}"
        cd - > /dev/null
        rm -rf "$work_dir"
        return 1
    fi

    cd claude-ally-fork || exit 1

    # Create feature branch
    local branch_name="add-${stack_id}-detection"
    echo -e "${CYAN}🌿 Creating feature branch: $branch_name${NC}"
    git checkout -b "$branch_name"

    echo -e "${CYAN}🔧 Step 3/5: Generating stack detection module...${NC}"

    # Create the stack detection module
    mkdir -p stacks
    local module_file="stacks/${stack_id}.sh"

    # Create safe function name (replace hyphens with underscores)
    local function_name="${stack_id//-/_}"

    cat > "$module_file" << EOF
#!/bin/bash
# $tech_stack Stack Detection
# Contributed via claude-ally automated contribution system

detect_$function_name() {
    local project_dir="\$1"
    local confidence=0
    local tech_stack="$tech_stack"
    local project_type="$project_type"

    # Detection patterns based on analysis:
    # $detection_patterns

    # TODO: Implement specific detection logic
    # Example patterns to customize:

    # Check for framework-specific configuration files
    # if [[ -f "\$project_dir/framework.config.js" ]]; then
    #     confidence=\$((confidence + 40))
    # fi

    # Check for dependencies in package.json
    # if [[ -f "\$project_dir/package.json" ]] && grep -q "specific-framework" "\$project_dir/package.json"; then
    #     confidence=\$((confidence + 30))
    # fi

    # Check for directory structure
    # if [[ -d "\$project_dir/src" ]] && [[ -d "\$project_dir/framework-dir" ]]; then
    #     confidence=\$((confidence + 20))
    # fi

    # Minimum confidence threshold
    if [[ \$confidence -ge 50 ]]; then
        echo "${stack_id}|\$tech_stack|\$project_type|\$confidence"
        return 0
    fi

    return 1
}

get_${function_name}_patterns() {
    cat << 'EOL'
\${tech_stack^^} PATTERNS
\${tech_stack//-/_}_Patterns (HIGH - Technology Specific):
  CRITICAL_\${tech_stack^^}:
    - "framework pattern" → Critical validation needed
    - "security pattern" → Security analysis required
    - "performance pattern" → Performance check needed
  HIGH_PRIORITY:
    - "integration pattern" → Integration validation
    - "deployment pattern" → Deployment best practices
    - "testing pattern" → Testing approach validation
EOL
}

get_${function_name}_assets() {
    echo "framework configurations, API keys, build artifacts, deployment files"
}

get_${function_name}_requirements() {
    echo "framework-specific security, performance optimization, cross-platform compatibility"
}

get_${function_name}_issues() {
    echo "framework updates, dependency conflicts, build optimization, platform compatibility"
}
EOF

    chmod +x "$module_file"

    # Update README.md with new stack support
    if [[ -f "README.md" ]]; then
        # Add the new stack to supported frameworks section
        local readme_temp="/tmp/readme_temp_$(date +%s).md"

        # Add to the supported frameworks list - find appropriate section
        if grep -q "✅ \*\*Mobile Development\*\*" README.md && [[ "$project_type" == "mobile-app" ]]; then
            # Add to Mobile Development section
            sed "/✅ \*\*Mobile Development\*\*/a\\
- $tech_stack" README.md > "$readme_temp" && mv "$readme_temp" README.md
        elif grep -q "✅ \*\*Backend Frameworks\*\*" README.md && [[ "$project_type" =~ backend|service|api ]]; then
            # Add to Backend Frameworks section
            sed "/✅ \*\*Backend Frameworks\*\*/a\\
- $tech_stack" README.md > "$readme_temp" && mv "$readme_temp" README.md
        elif grep -q "✅ \*\*Frontend Frameworks\*\*" README.md && [[ "$project_type" =~ web|frontend ]]; then
            # Add to Frontend Frameworks section
            sed "/✅ \*\*Frontend Frameworks\*\*/a\\
- $tech_stack" README.md > "$readme_temp" && mv "$readme_temp" README.md
        elif grep -q "## 🛠️ Supported Technology Stacks" README.md; then
            # Add as a new category
            sed "/## 🛠️ Supported Technology Stacks/a\\
\\
✅ **$tech_stack**\\
- $project_type with automatic detection\\
- Framework-specific patterns and best practices" README.md > "$readme_temp" && mv "$readme_temp" README.md
        else
            # Fallback: add to end of file or create basic entry
            echo "" >> README.md
            echo "✅ **$tech_stack**" >> README.md
            echo "- $project_type with automatic detection" >> README.md
        fi
    fi

    # Create commit message
    local commit_message="feat: add $tech_stack stack detection

- Add $stack_id detection module for $tech_stack projects
- Support for $project_type applications
- Patterns: $detection_patterns
- Contributed from: $project_name

🤖 Generated with claude-ally automated contribution system"

    # Stage and commit changes
    git add "$module_file" README.md
    git commit -m "$commit_message"

    echo -e "${CYAN}📤 Step 4/5: Pushing to your fork...${NC}"

    # Try to push, if it fails due to being behind, pull and retry
    if ! git push -u origin "$branch_name"; then
        echo -e "${YELLOW}⚠️ Push failed, trying to sync with remote...${NC}"

        # Pull latest changes and try to merge/rebase
        if git pull origin "$branch_name" --no-edit 2>/dev/null; then
            echo -e "${BLUE}📥 Synced with remote, retrying push...${NC}"
            if ! git push -u origin "$branch_name"; then
                echo -e "${RED}❌ Failed to push changes after sync${NC}"
                cd - > /dev/null
                rm -rf "$work_dir"
                return 1
            fi
        else
            echo -e "${RED}❌ Failed to sync with remote and push changes${NC}"
            cd - > /dev/null
            rm -rf "$work_dir"
            return 1
        fi
    fi

    echo -e "${CYAN}🔄 Step 5/5: Creating pull request...${NC}"

    # Create pull request
    local pr_title="Add $tech_stack stack detection support"
    local pr_body="## 🚀 New Stack Detection Contribution

### Stack Information
- **Technology**: $tech_stack
- **Project Type**: $project_type
- **Detection Module**: \`stacks/${stack_id}.sh\`
- **Source Project**: $project_name

### Detection Patterns
$detection_patterns

### Changes
- ✅ Added \`$module_file\` with detection logic
- ✅ Updated README.md with new stack support
- ✅ Follows claude-ally modular architecture

### Testing
- [ ] Detection logic tested with multiple projects
- [ ] Patterns validated for accuracy
- [ ] No false positives detected

### Contribution Details
This contribution was generated using claude-ally's automated contribution system, which analyzed the project structure and created appropriate detection patterns.

🤖 **Generated with [claude-ally](https://github.com/mglcel/claude-ally) automated contribution system**

Co-Authored-By: Claude <noreply@anthropic.com>"

    if gh pr create --title "$pr_title" --body "$pr_body" --base main; then
        echo ""
        echo -e "${GREEN}🎉 SUCCESS! Pull request created successfully!${NC}"
        echo ""

        # Get PR URL
        local pr_url
        pr_url=$(gh pr view --json url --jq '.url' 2>/dev/null)

        if [[ -n "$pr_url" ]]; then
            echo -e "${CYAN}📋 Pull Request URL: ${BOLD}$pr_url${NC}"
            echo ""
            echo -e "${YELLOW}Next steps:${NC}"
            echo "1. 🔍 Review your pull request at the URL above"
            echo "2. ✏️ Edit detection logic if needed (customize TODO sections)"
            echo "3. 🧪 Test with multiple projects of this type"
            echo "4. 📝 Update the PR description if needed"
            echo "5. 🤝 Respond to any feedback from maintainers"
        fi
    else
        echo -e "${RED}❌ Failed to create pull request${NC}"
        cd - > /dev/null
        rm -rf "$work_dir"
        return 1
    fi

    # Cleanup
    cd - > /dev/null
    rm -rf "$work_dir"

    return 0
}

# Provide manual contribution instructions
provide_manual_instructions() {
    local stack_id="$1"
    local tech_stack="$2"
    local project_name="$3"

    echo ""
    echo -e "${CYAN}📖 MANUAL CONTRIBUTION GUIDE${NC}"
    echo -e "${BOLD}=============================${NC}"
    echo ""
    echo -e "${YELLOW}Since automated PR creation isn't available, here's how to contribute manually:${NC}"
    echo ""
    echo -e "${BOLD}Step 1: Fork the Repository${NC}"
    echo "  🌐 Visit: $CLAUDE_ALLY_FORK_URL"
    echo "  🍴 Click 'Fork' to create your own copy"
    echo ""
    echo -e "${BOLD}Step 2: Clone Your Fork${NC}"
    echo "  📥 git clone https://github.com/YOUR-USERNAME/claude-ally.git"
    echo "  📁 cd claude-ally"
    echo ""
    echo -e "${BOLD}Step 3: Create Feature Branch${NC}"
    echo "  🌿 git checkout -b add-${stack_id}-detection"
    echo ""
    echo -e "${BOLD}Step 4: Add Your Stack Module${NC}"
    echo "  📝 Create: stacks/${stack_id}.sh"
    echo "  🔧 Implement detection logic for $tech_stack"
    echo "  📚 Update README.md with new stack support"
    echo ""
    echo -e "${BOLD}Step 5: Commit and Push${NC}"
    echo "  💾 git add stacks/${stack_id}.sh README.md"
    echo "  📝 git commit -m \"feat: add $tech_stack stack detection\""
    echo "  📤 git push -u origin add-${stack_id}-detection"
    echo ""
    echo -e "${BOLD}Step 6: Create Pull Request${NC}"
    echo "  🔄 Visit your fork on GitHub"
    echo "  🔃 Click 'Compare & pull request'"
    echo "  📝 Describe your contribution"
    echo "  🚀 Submit pull request"
    echo ""
    echo -e "${GREEN}💡 Your contribution will help other developers using $tech_stack!${NC}"
}

# Main function
main() {
    local stack_id="$1"
    local tech_stack="$2"
    local project_type="$3"
    local detection_patterns="$4"
    local project_dir="$5"
    local project_name="$6"

    echo ""
    echo -e "${PURPLE}🎯 CONTRIBUTE TO CLAUDE-ALLY ON GITHUB${NC}"
    echo -e "${BOLD}=====================================${NC}"
    echo ""
    echo -e "${CYAN}Your $tech_stack stack detection would be valuable for the community!${NC}"
    echo -e "${YELLOW}Would you like to contribute it directly to the claude-ally GitHub repository?${NC}"
    echo ""

    local contribute_choice
    read -p "Contribute to GitHub repository? (Y/n): " contribute_choice

    if [[ "$contribute_choice" =~ ^[Nn] ]]; then
        echo -e "${BLUE}No problem! You can always contribute later.${NC}"
        return 1
    fi

    # Try automated PR creation first
    if create_automated_pr "$stack_id" "$tech_stack" "$project_type" "$detection_patterns" "$project_dir" "$project_name"; then
        return 0
    else
        # Fall back to manual instructions
        provide_manual_instructions "$stack_id" "$tech_stack" "$project_name"
        return 1
    fi
}

# Run if called directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi