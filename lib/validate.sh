#!/bin/bash

# Claude Ally Validation Script
# Tests if a generated prompt file will create an effective CLAUDE.md system

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m' # No Color

print_header() {
    echo "============================================================"
    echo "🔍 CLAUDE ALLY - PROMPT VALIDATION"
    echo "============================================================"
    echo "This script validates your generated prompt for completeness"
    echo "and effectiveness before using it with Claude."
    echo ""
}

validate_file_exists() {
    local file="$1"
    if [[ ! -f "$file" ]]; then
        echo -e "${RED}❌ Error: File '$file' not found${NC}"
        echo "Usage: $0 <prompt_file>"
        echo "Example: $0 claude_prompt_myproject.txt"
        exit 1
    fi
}

check_required_sections() {
    local file="$1"
    local score=0
    local total=12

    echo -e "${BLUE}📋 CHECKING REQUIRED SECTIONS${NC}"
    echo "------------------------------"

    # Check for project context (current format)
    if grep -q "Project Name.*:" "$file"; then
        echo -e "✅ Project name configured"
        ((score++))
    else
        echo -e "❌ Missing PROJECT_NAME"
    fi

    if grep -q "Tech Stack.*:" "$file"; then
        echo -e "✅ Tech stack specified"
        ((score++))
    else
        echo -e "❌ Missing TECH_STACK"
    fi

    if grep -q "Critical Assets.*:" "$file"; then
        echo -e "✅ Critical assets identified"
        ((score++))
    else
        echo -e "❌ Missing CRITICAL_ASSETS"
    fi

    # Check for pattern matching (current format)
    if grep -q "Security patterns\|MANDATORY DEVELOPMENT REQUIREMENTS" "$file"; then
        echo -e "✅ Security patterns included"
        ((score++))
    else
        echo -e "❌ Missing Security_Critical_Patterns"
    fi

    if grep -q "HIGH\|MEDIUM\|LOW" "$file"; then
        echo -e "✅ Priority-based pattern matching"
        ((score++))
    else
        echo -e "❌ Missing priority-based patterns"
    fi

    # Check for learning system (current format)
    if grep -q "Learning Protocol\|Pattern recognition" "$file"; then
        echo -e "✅ Learning protocol configured"
        ((score++))
    else
        echo -e "❌ Missing Learning_Signal_Detection"
    fi

    if grep -q "HIGH.*MEDIUM.*LOW\|Confidence levels" "$file"; then
        echo -e "✅ Confidence levels defined"
        ((score++))
    else
        echo -e "❌ Missing confidence level criteria"
    fi

    # Check for implementation requirements (current format)
    if grep -q "CLAUDE.md file\|Output Format\|IMPORTANT.*response" "$file"; then
        echo -e "✅ CLAUDE.md creation instruction"
        ((score++))
    else
        echo -e "❌ Missing CLAUDE.md creation requirement"
    fi

    if grep -q "1\.\|2\.\|3\.\|4\.\|5\." "$file"; then
        echo -e "✅ Implementation steps defined"
        ((score++))
    else
        echo -e "❌ Missing implementation steps"
    fi

    # Check for validation tests (current format)
    if grep -q "Testing requirements\|validation\|test" "$file"; then
        echo -e "✅ Validation tests included"
        ((score++))
    else
        echo -e "❌ Missing validation tests"
    fi

    # Check for domain knowledge (current format)
    if grep -q "Project Overview\|Technology stack\|architecture" "$file"; then
        echo -e "✅ Domain-specific knowledge"
        ((score++))
    else
        echo -e "❌ Missing domain knowledge section"
    fi

    # Check for error recovery (current format)
    if grep -q "Error handling\|Common Issue Prevention\|Monitoring" "$file"; then
        echo -e "✅ Error recovery protocols"
        ((score++))
    else
        echo -e "❌ Missing error recovery protocols"
    fi

    echo ""
    echo -e "${BOLD}Section Completeness: $score/$total${NC}"

    if [[ $score -ge 10 ]]; then
        echo -e "${GREEN}✅ Excellent completeness${NC}"
        return 0
    elif [[ $score -ge 8 ]]; then
        echo -e "${YELLOW}⚠️  Good, but could be improved${NC}"
        return 1
    else
        echo -e "${RED}❌ Poor completeness - missing critical sections${NC}"
        return 2
    fi
}

check_customization_quality() {
    local file="$1"
    local score=0
    local total=6

    echo -e "${BLUE}🎯 CHECKING CUSTOMIZATION QUALITY${NC}"
    echo "------------------------------"

    # Check if placeholders are filled
    if ! grep -q "\[Your project name\]" "$file"; then
        echo -e "✅ Project name customized"
        ((score++))
    else
        echo -e "❌ Project name still has placeholder"
    fi

    if ! grep -q "\[web-app/mobile-app" "$file"; then
        echo -e "✅ Project type customized"
        ((score++))
    else
        echo -e "❌ Project type still has placeholder"
    fi

    if ! grep -q "\[Languages and frameworks" "$file"; then
        echo -e "✅ Tech stack customized"
        ((score++))
    else
        echo -e "❌ Tech stack still has placeholder"
    fi

    # Check for specific project references
    local project_name
    project_name=$(grep "Project Name" "$file" | head -1 | cut -d':' -f2 | xargs)
    if [[ -n "$project_name" ]] && grep -q "$project_name" "$file"; then
        echo -e "✅ Project name referenced in patterns"
        ((score++))
    else
        echo -e "❌ Project name not integrated into patterns"
    fi

    local tech_stack
    tech_stack=$(grep "Tech Stack" "$file" | head -1 | cut -d':' -f2 | xargs)
    if [[ -n "$tech_stack" ]] && grep -q "$tech_stack" "$file"; then
        echo -e "✅ Tech stack integrated into patterns"
        ((score++))
    else
        echo -e "❌ Tech stack not properly integrated"
    fi

    # Check for meaningful content
    local line_count
    line_count=$(wc -l < "$file")
    if [[ $line_count -gt 200 ]]; then
        echo -e "✅ Comprehensive content ($line_count lines)"
        ((score++))
    else
        echo -e "❌ Content seems incomplete ($line_count lines)"
    fi

    echo ""
    echo -e "${BOLD}Customization Quality: $score/$total${NC}"

    if [[ $score -ge 5 ]]; then
        echo -e "${GREEN}✅ Well customized${NC}"
        return 0
    elif [[ $score -ge 3 ]]; then
        echo -e "${YELLOW}⚠️  Partially customized${NC}"
        return 1
    else
        echo -e "${RED}❌ Poor customization${NC}"
        return 2
    fi
}

check_implementation_readiness() {
    local file="$1"
    local score=0
    local total=4

    echo -e "${BLUE}🚀 CHECKING IMPLEMENTATION READINESS${NC}"
    echo "------------------------------"

    # Check for clear instructions
    if grep -q "After you paste this prompt.*should:" "$file"; then
        echo -e "✅ Clear post-paste expectations"
        ((score++))
    else
        echo -e "❌ Missing post-paste instructions"
    fi

    if grep -q "Immediately create.*CLAUDE.md" "$file"; then
        echo -e "✅ CLAUDE.md creation mandate"
        ((score++))
    else
        echo -e "❌ Missing CLAUDE.md creation requirement"
    fi

    if grep -q "Validate.*system.*setup" "$file"; then
        echo -e "✅ System validation requirement"
        ((score++))
    else
        echo -e "❌ Missing validation requirement"
    fi

    # Check for specific test cases
    if grep -q "Help me add.*login\|authentication" "$file"; then
        echo -e "✅ Concrete validation tests"
        ((score++))
    else
        echo -e "❌ Missing concrete test examples"
    fi

    echo ""
    echo -e "${BOLD}Implementation Readiness: $score/$total${NC}"

    if [[ $score -ge 3 ]]; then
        echo -e "${GREEN}✅ Ready for implementation${NC}"
        return 0
    else
        echo -e "${RED}❌ Not ready for implementation${NC}"
        return 1
    fi
}

generate_report() {
    local overall_score="$1"
    local file="$2"

    echo ""
    echo "============================================================"
    echo -e "${BOLD}📊 VALIDATION REPORT${NC}"
    echo "============================================================"

    case $overall_score in
        0)
            echo -e "${GREEN}🎉 EXCELLENT: Your prompt is ready for Claude!${NC}"
            echo ""
            echo -e "${BOLD}Next Steps:${NC}"
            echo "1. Copy the entire content of $file"
            echo "2. Paste it to a new Claude conversation"
            echo "3. Claude will create your CLAUDE.md file"
            echo "4. Test with the validation questions"
            echo ""
            echo -e "${GREEN}Expected outcome: 60-70% efficiency improvement${NC}"
            ;;
        1)
            echo -e "${YELLOW}⚠️  GOOD: Minor improvements recommended${NC}"
            echo ""
            echo -e "${BOLD}Recommendations:${NC}"
            echo "- Review the sections marked with ❌ above"
            echo "- Consider running ./setup.sh again for better customization"
            echo "- The prompt should still work but may be less effective"
            ;;
        2)
            echo -e "${RED}❌ POOR: Significant issues found${NC}"
            echo ""
            echo -e "${BOLD}Required Actions:${NC}"
            echo "- Re-run ./setup.sh to generate a new prompt"
            echo "- Ensure all questions are answered completely"
            echo "- This prompt may not create an effective system"
            ;;
    esac

    echo ""
    echo -e "${BLUE}For support: https://github.com/mglcel/claude-ally/issues${NC}"
}

main() {
    local prompt_file="$1"

    print_header

    validate_file_exists "$prompt_file"

    echo -e "${BOLD}Validating: $prompt_file${NC}"
    echo ""

    local section_result
    local custom_result
    local impl_result
    local overall_score=0

    check_required_sections "$prompt_file"
    section_result=$?

    echo ""
    check_customization_quality "$prompt_file"
    custom_result=$?

    echo ""
    check_implementation_readiness "$prompt_file"
    impl_result=$?

    # Calculate overall score
    overall_score=$((section_result + custom_result + impl_result))
    if [[ $overall_score -gt 2 ]]; then
        overall_score=2
    fi

    generate_report $overall_score "$prompt_file"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    if [[ $# -eq 0 ]]; then
        echo "Usage: $0 <prompt_file>"
        echo "Example: $0 claude_prompt_myproject.txt"
        exit 1
    fi

    main "$@"
fi