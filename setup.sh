#!/bin/bash

# Claude Ally Setup Script
# Generates a customized prompt for creating your project's CLAUDE.md file.

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
    echo "🤖 CLAUDE ALLY - COGNITIVE ENHANCEMENT SETUP"
    echo "============================================================"
    echo "This script will help you create a customized prompt to set up"
    echo "Claude's cognitive enhancement system for your project."
    echo ""
}

get_project_info() {
    echo -e "${BLUE}📋 PROJECT INFORMATION${NC}"
    echo "------------------------------"

    read -p "Project name: " PROJECT_NAME

    echo ""
    echo "Project type:"
    echo "1. Web application"
    echo "2. Mobile app"
    echo "3. Desktop application"
    echo "4. Backend service/API"
    echo "5. Data pipeline"
    echo "6. Embedded system"
    echo "7. Other"

    read -p "Select project type (1-7): " PROJECT_TYPE_CHOICE

    case $PROJECT_TYPE_CHOICE in
        1) PROJECT_TYPE="web-app" ;;
        2) PROJECT_TYPE="mobile-app" ;;
        3) PROJECT_TYPE="desktop-app" ;;
        4) PROJECT_TYPE="backend-service" ;;
        5) PROJECT_TYPE="data-pipeline" ;;
        6) PROJECT_TYPE="embedded-system" ;;
        7) read -p "Please specify: " PROJECT_TYPE ;;
        *) PROJECT_TYPE="web-app" ;;
    esac

    read -p "Tech stack (e.g., 'Java/Spring Boot, React, PostgreSQL'): " TECH_STACK

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

    read -p "Select database (1-8): " DB_CHOICE

    case $DB_CHOICE in
        1) DATABASE_TECH="PostgreSQL" ;;
        2) DATABASE_TECH="MySQL" ;;
        3) DATABASE_TECH="MongoDB" ;;
        4) DATABASE_TECH="SQLite" ;;
        5) DATABASE_TECH="Redis" ;;
        6) read -p "Specify databases: " DATABASE_TECH ;;
        7) DATABASE_TECH="None" ;;
        8) read -p "Specify database: " DATABASE_TECH ;;
        *) DATABASE_TECH="PostgreSQL" ;;
    esac
}

get_security_info() {
    echo ""
    echo -e "${BLUE}🔒 SECURITY & COMPLIANCE${NC}"
    echo "------------------------------"

    read -p "Most critical assets (e.g., 'user data, payment info, API keys'): " CRITICAL_ASSETS

    echo ""
    echo "Compliance requirements:"
    echo "1. GDPR"
    echo "2. HIPAA"
    echo "3. SOC 2"
    echo "4. PCI DSS"
    echo "5. Multiple"
    echo "6. None"
    echo "7. Other"

    read -p "Select compliance (1-7): " COMPLIANCE_CHOICE

    case $COMPLIANCE_CHOICE in
        1) MANDATORY_REQUIREMENTS="GDPR compliance" ;;
        2) MANDATORY_REQUIREMENTS="HIPAA compliance" ;;
        3) MANDATORY_REQUIREMENTS="SOC 2 compliance" ;;
        4) MANDATORY_REQUIREMENTS="PCI DSS compliance" ;;
        5) read -p "Specify requirements: " MANDATORY_REQUIREMENTS ;;
        6) MANDATORY_REQUIREMENTS="None" ;;
        7) read -p "Specify requirements: " MANDATORY_REQUIREMENTS ;;
        *) MANDATORY_REQUIREMENTS="" ;;
    esac
}

get_technical_info() {
    echo ""
    echo -e "${BLUE}⚙️ TECHNICAL DETAILS${NC}"
    echo "------------------------------"

    read -p "Common issues you face (e.g., 'performance bottlenecks, memory leaks'): " COMMON_ISSUES

    read -p "File structure overview (e.g., 'src/main/java, gradle build'): " FILE_STRUCTURE

    echo ""
    echo "Deployment target:"
    echo "1. Cloud containers (Docker/Kubernetes)"
    echo "2. Mobile devices"
    echo "3. Desktop OS"
    echo "4. Embedded hardware"
    echo "5. Multiple platforms"
    echo "6. Other"

    read -p "Select deployment (1-6): " DEPLOY_CHOICE

    case $DEPLOY_CHOICE in
        1) DEPLOYMENT_TARGET="cloud containers" ;;
        2) DEPLOYMENT_TARGET="mobile devices" ;;
        3) DEPLOYMENT_TARGET="desktop OS" ;;
        4) DEPLOYMENT_TARGET="embedded hardware" ;;
        5) read -p "Specify platforms: " DEPLOYMENT_TARGET ;;
        6) read -p "Specify target: " DEPLOYMENT_TARGET ;;
        *) DEPLOYMENT_TARGET="cloud containers" ;;
    esac
}

generate_prompt() {
    local filename="claude_prompt_$(echo "$PROJECT_NAME" | tr '[:upper:]' '[:lower:]' | tr ' ' '_').txt"

    cat > "$filename" << EOF
## (Fill in the [bracketed] sections with your project details first)

## **PROJECT CONTEXT TO FILL**

PROJECT_NAME: $PROJECT_NAME
PROJECT_TYPE: $PROJECT_TYPE
TECH_STACK: $TECH_STACK
DATABASE_TECH: $DATABASE_TECH
CRITICAL_ASSETS: $CRITICAL_ASSETS
MANDATORY_REQUIREMENTS: $MANDATORY_REQUIREMENTS
COMMON_ISSUES: $COMMON_ISSUES
FILE_STRUCTURE: $FILE_STRUCTURE
DEPLOYMENT_TARGET: $DEPLOYMENT_TARGET

## **SYSTEM COMPONENTS TO IMPLEMENT**

### **1. CONTEXT-AWARE DECISION ENHANCEMENT**

Create project-specific mindset triggers:

Critical_Priority_Areas:
  - $CRITICAL_ASSETS: Enhanced protection protocols
  - $TECH_STACK: Framework-specific best practices
  - $DEPLOYMENT_TARGET: Platform-specific optimization

Mandatory_Validation_Rules:
  - $MANDATORY_REQUIREMENTS: Compliance verification required
  - $COMMON_ISSUES: Prevention analysis required
  - $CRITICAL_ASSETS operations: Security validation required

### **2. PRIORITY-BASED PATTERN MATCHING**

**Processing Order: CRITICAL → HIGH → MEDIUM → NORMAL**

**CRITICAL (Immediate Analysis Required):**

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

**HIGH (Enhanced Analysis):**

${TECH_STACK}_Specific_Patterns:
  - $TECH_STACK framework patterns → Framework-specific validations
  - $DATABASE_TECH database patterns → Database-specific checks
  - $PROJECT_TYPE architecture patterns → Application-specific best practices

Performance_Critical:
  - "$COMMON_ISSUES" → Performance impact analysis required
  - "loop", "recursive", "async", "parallel" → Performance and resource analysis
  - "$DEPLOYMENT_TARGET" constraints → Platform-specific optimization

**MEDIUM (Standard Analysis):**

Compatibility_Validation:
  - "$MANDATORY_REQUIREMENTS" → Compliance verification
  - "dependency", "import", "package" → Compatibility impact analysis
  - "version", "upgrade", "migration" → Version compatibility check

**NORMAL (Background Analysis):**

Code_Quality_Patterns:
  - "TODO", "FIXME", "HACK" → Code quality improvement suggestions
  - "test", "spec", "mock" → Testing approach recommendations
  - "documentation", "comment" → Documentation enhancement suggestions

### **3. UNIVERSAL APPLICATION PATTERNS**

Choose the pattern set that matches your PROJECT_TYPE: $PROJECT_TYPE

### **4. DOMAIN KNOWLEDGE INTEGRATION**

**Technology Stack Expertise for $TECH_STACK:**

${TECH_STACK}_Best_Practices:
  - Performance optimization for $DEPLOYMENT_TARGET
  - Security patterns for $CRITICAL_ASSETS protection
  - Architecture patterns for $PROJECT_TYPE applications

${DATABASE_TECH}_Optimization:
  - Query optimization for $DATABASE_TECH
  - Security patterns for $CRITICAL_ASSETS storage
  - Performance tuning for $DEPLOYMENT_TARGET

**Domain-Specific Knowledge for $PROJECT_TYPE:**

${PROJECT_TYPE}_Architecture_Principles:
  - Scalability patterns for $DEPLOYMENT_TARGET
  - Security requirements for $CRITICAL_ASSETS
  - Performance optimization for common issues: $COMMON_ISSUES

Industry_Standards_$(echo "$PROJECT_NAME" | tr ' ' '_'):
  - $MANDATORY_REQUIREMENTS → Implementation approach
  - $CRITICAL_ASSETS security → Validation method
  - $DEPLOYMENT_TARGET performance → Measurement approach

### **5. LEARNING ENHANCEMENT TRIGGERS**

**Continuous Improvement Protocol:**

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

### **6. ERROR RECOVERY PROTOCOLS**

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

### **7. PROACTIVE LEARNING PROTOCOL**

**After Each Task - MANDATORY:**

🔍 LEARNING IDENTIFIED: [Specific gap or improvement discovered]
📝 PROPOSED CLAUDE.md UPDATE: [Exact text to add/modify]
🎯 REASONING: [Why this will prevent future errors]
📊 CONFIDENCE LEVEL: [HIGH/MEDIUM/LOW based on evidence strength]
✅ USER APPROVAL NEEDED: [Yes/No for implementation]

**CONFIDENCE LEVEL CRITERIA (Critical for Effective Learning):**

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

**Build this system step by step, explaining reasoning for each component and how it aligns with the specific project needs.**

**Remember: The goal is sophisticated intelligence that enhances natural decision-making, not complex artificial coordination.**

---

## **IMPLEMENTATION REQUIREMENTS - MANDATORY FIRST STEPS**

**⚡ CRITICAL: After confirming this setup, you MUST immediately:**

### **STEP 1: Create CLAUDE.md File**
Create a \`CLAUDE.md\` file in the project root with the complete cognitive enhancement system configured for this specific project. Include:
- All the patterns above, customized with the actual $PROJECT_NAME, $TECH_STACK, etc.
- The learning protocol for continuous improvement
- Project-specific security and compatibility requirements
- Clear documentation for future Claude conversations

### **STEP 2: Implement Learning System**
Set up the proactive learning protocol by:
- Adding the confidence-based learning assessment system
- Creating a system for documenting pattern improvements
- Establishing the HIGH/MEDIUM/LOW confidence criteria
- Setting up the mechanism for CLAUDE.md updates based on learning

### **STEP 3: Validate System Setup**
Confirm the cognitive enhancement system is working by:
- Testing pattern recognition with a sample task
- Verifying security analysis triggers correctly
- Checking that tech stack expertise is active
- Ensuring the learning protocol responds to task outcomes

**ONLY AFTER completing these implementation steps should you signal readiness for development tasks.**

---

**⚡ EXPECTED RESPONSE: After you paste this prompt, I (Claude) should:**
1. **Confirm** understanding of your project domain and tech stack
2. **Immediately create** the CLAUDE.md file with your customized system
3. **Implement** the learning protocol for continuous improvement
4. **Validate** the system setup with a test
5. **Signal readiness** for your first development task

**If I don't create the CLAUDE.md file and implement the system, the prompt setup is incomplete.**
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

main() {
    print_header

    # Collect information
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

        # Validate the generated file
        if command -v ./validate.sh &> /dev/null; then
            echo ""
            echo -e "${BLUE}🔍 Running validation check...${NC}"
            if ./validate.sh "$filename" | tail -1 | grep -q "EXCELLENT"; then
                echo -e "${GREEN}✅ Validation passed!${NC}"
            else
                echo -e "${YELLOW}⚠️  Validation found minor issues (check above)${NC}"
            fi
        fi

        echo ""
        echo -e "${YELLOW}📋 NEXT STEPS:${NC}"
        echo "1. Open the generated file: $filename"
        echo "2. Copy the entire content"
        echo "3. Paste it to a new Claude conversation"
        echo "4. Claude will create your CLAUDE.md file and set up the system"
        echo ""
        echo -e "${BOLD}💡 TIP: Use './validate.sh $filename' to check prompt quality${NC}"
        echo ""
        echo -e "${GREEN}🚀 Your project will then have the same sophisticated Claude${NC}"
        echo -e "${GREEN}   cognitive enhancement system we built together!${NC}"
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