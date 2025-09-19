# CLAUDE.md

## Project Overview
claude-ally - cli-tool using Shell scripting, Markdown, Git

## 🚨 MANDATORY DEVELOPMENT REQUIREMENTS - NEVER SKIP THESE

### Core Development Rules
- Always commit changes once done
- Try to update documentation and README files when done
- Write tests for changes and eventually adapt existing ones
- When making changes ensure you check all implications/dependencies, analyze callers, documentation, signatures
- When using python, use venv
- Always run tests after a commit to ensure nothing is broken
- **🔥 CRITICAL: MUST wait for GitHub Actions workflows to pass before considering work complete**
  - Never give up the prompt to user while GitHub Actions are failing
  - Continue debugging and fixing until ALL CI/CD workflows pass
  - Only consider development task finished when tests pass in CI environment
  - GitHub Actions success is mandatory for task completion

### Project-Specific Critical Assets
- Configuration files, environment variables: Enhanced protection protocols required
- Shell scripts: Framework-specific best practices enforcement
- Markdown documentation: Consistency and clarity standards
- Git operations: Repository integrity and history preservation

## 🧠 COGNITIVE ENHANCEMENT SYSTEM

### 1. CONTEXT-AWARE DECISION ENHANCEMENT

#### Critical Priority Areas
**Configuration files, environment variables**: Enhanced protection protocols
- Never commit secrets or sensitive data
- Validate environment variable usage
- Ensure proper escaping and quoting in shell scripts
- Check for hardcoded paths and make them portable

**Shell scripting, Markdown, Git**: Framework-specific best practices
- Follow POSIX compliance where possible
- Use proper error handling with set -e and error checking
- Validate markdown syntax and consistency
- Ensure git operations are safe and reversible

**Developer workstations**: Platform-specific optimization
- Support cross-platform compatibility (macOS, Linux, Windows)
- Optimize for local development environments
- Minimize setup complexity and dependencies

#### Mandatory Validation Rules
**Prompt customization complexity, setup time**: Prevention analysis required
- Simplify configuration processes
- Provide clear, step-by-step instructions
- Minimize manual intervention requirements
- Test setup procedures on clean environments

**Configuration files, environment variables operations**: Security validation required
- Scan for exposed secrets before commits
- Validate file permissions and access controls
- Check for injection vulnerabilities in shell scripts
- Ensure sensitive data is properly handled

### 2. PRIORITY-BASED PATTERN MATCHING

#### CRITICAL (Immediate Analysis Required)

**Security_Critical_Patterns**:
- "authentication", "authorization", "login", "password", "token", "session" → Security analysis required
- "config", "env", "environment", "secret", "key", "credential" → Credential security analysis
- "eval", "exec", "system", "shell_exec" → Command injection prevention
- "curl", "wget", "download", "fetch" → Network security validation
- Configuration files, environment variables → Enhanced protection protocols

**Data_Integrity_Critical**:
- Configuration files, environment variables operations → Data validation and backup verification
- "rm", "delete", "unlink", "truncate" → Data loss prevention analysis
- "chmod", "chown", "permission" → Access control validation
- Git operations affecting history → Repository integrity checks

#### HIGH (Enhanced Analysis)

**Shell_Scripting_Specific_Patterns**:
- Shell script patterns → POSIX compliance and error handling validation
- Markdown patterns → Syntax and formatting consistency checks
- Git patterns → Repository safety and best practices
- CLI tool architecture patterns → User experience and reliability best practices

**Performance_Critical**:
- "prompt customization complexity, setup time" → Performance impact analysis required
- "loop", "while", "for", "recursive" → Performance and resource analysis
- "developer workstations" constraints → Platform-specific optimization
- "timeout", "retry", "async" → Reliability and responsiveness analysis

#### MEDIUM (Standard Analysis)

**Compatibility_Validation**:
- Cross-platform compatibility → Multi-OS testing verification
- "dependency", "require", "import" → Compatibility impact analysis
- "version", "upgrade", "migration" → Version compatibility check
- Shell variations → Bash/zsh/sh compatibility validation

#### NORMAL (Background Analysis)

**Code_Quality_Patterns**:
- "TODO", "FIXME", "HACK" → Code quality improvement suggestions
- "test", "spec", "validate" → Testing approach recommendations
- "documentation", "comment", "readme" → Documentation enhancement suggestions
- "cleanup", "refactor", "optimize" → Code maintenance opportunities

### 3. TECHNOLOGY STACK EXPERTISE

#### Shell Scripting Best Practices
- Use `set -euo pipefail` for robust error handling
- Quote variables properly: `"$variable"` not `$variable`
- Use `[[` instead of `[` for better functionality
- Implement proper argument validation
- Use functions for reusable code blocks
- Handle edge cases and error conditions

#### Markdown Standards
- Consistent heading hierarchy
- Proper code block syntax highlighting
- Clear table formatting
- Consistent link formatting
- Proper list indentation and structure

#### Git Operations Safety
- Always check repository state before operations
- Use descriptive commit messages
- Validate branch operations
- Ensure clean working directory when needed
- Implement proper conflict resolution

### 4. CLI Tool Architecture Principles

#### User Experience Optimization
- Clear, helpful error messages
- Progress indicators for long operations
- Intuitive command structure
- Comprehensive help documentation
- Graceful handling of edge cases

#### Reliability Requirements
- Robust error handling and recovery
- Validation of user inputs
- Safe defaults and confirmations
- Logging for debugging and troubleshooting
- Clean rollback capabilities

#### Performance Considerations
- Minimize startup time
- Efficient file operations
- Avoid unnecessary dependencies
- Cache expensive operations where appropriate
- Optimize for common use cases

### 5. LEARNING ENHANCEMENT TRIGGERS

#### Continuous Improvement Protocol

**Learning_Signal_Detection**:
- When issues are caught that patterns missed → HIGH confidence learning opportunity
- When optimizations are suggested → MEDIUM confidence pattern enhancement
- When unexpected behavior occurs → HIGH confidence gap identification
- When patterns successfully prevent problems → HIGH confidence pattern validation

**Proactive_Documentation_Updates**:
TRIGGER_CONDITIONS:
- New security vulnerabilities discovered → Update CRITICAL security patterns
- Shell scripting best practices evolved → Update framework patterns
- Performance bottlenecks identified → Update optimization guidelines
- User experience issues resolved → Update UX patterns

**Learning_Confidence_Assessment**:
HIGH_CONFIDENCE (Immediate CLAUDE.md Update):
- Clear error prevented by missing pattern
- Security vulnerability caught through pattern gap
- Performance issue solved through specific optimization
- User workflow problem resolved through targeted improvement

MEDIUM_CONFIDENCE (Propose for Next Update):
- Efficiency improvement observed through better pattern
- User experience enhanced through refined approach
- Pattern refinement improves accuracy without noise

LOW_CONFIDENCE (Monitor for Patterns):
- Theoretical improvement without concrete evidence
- Single-occurrence issue without pattern validation
- Preference-based suggestion without clear benefit

#### Context Stack Awareness
**CROSS_TASK_MEMORY**:
- Remember configuration decisions from previous tasks
- Build on established patterns within conversation
- Reference previous solutions for consistency
- Maintain awareness of project evolution and user preferences

### 6. ERROR RECOVERY PROTOCOLS

#### Pattern Miss Detection
- "Did any security, compatibility, or user experience issues emerge that patterns should have caught?"
- "Are there shell scripting, git operations, or configuration problems not flagged?"

#### Secondary Validation Checks
**Security_Backstop**:
- Final scan for configuration files and environment variable security patterns
- Double-check that credential/secret patterns weren't missed
- Verify shell injection vulnerabilities are addressed

**Technical_Backstop**:
- Scan for setup complexity that might impact user experience
- Verify cross-platform compatibility wasn't overlooked
- Check for missing error handling or edge cases

#### Pattern Improvement Triggers
- "If setup complexity was missed, what pattern should have caught it?"
- "What keyword would have triggered proper cross-platform analysis?"

### 7. PROACTIVE LEARNING PROTOCOL

#### After Each Task - MANDATORY

🔍 **LEARNING IDENTIFIED**: [Specific gap or improvement discovered]
📝 **PROPOSED CLAUDE.md UPDATE**: [Exact text to add/modify]
🎯 **REASONING**: [Why this will prevent future errors]
📊 **CONFIDENCE LEVEL**: [HIGH/MEDIUM/LOW based on evidence strength]
✅ **USER APPROVAL NEEDED**: [Yes/No for implementation]

#### CONFIDENCE LEVEL CRITERIA

**HIGH_CONFIDENCE_Learning**:
- Clear errors prevented (security vulnerability caught, setup complexity avoided)
- Missing pattern discovered through actual failure
- User feedback indicating specific improvement needed
- Concrete evidence of system gap from real task outcomes

**MEDIUM_CONFIDENCE_Learning**:
- Efficiency improvements observed during tasks
- Pattern refinements that improve accuracy
- User behavior patterns that suggest optimization
- Successful prevention that could be coincidental

**LOW_CONFIDENCE_Learning**:
- Theoretical improvements without concrete evidence
- Single occurrence without pattern validation
- Preference-based changes without clear benefit
- Speculative enhancements without proven value

## 🛡️ SECURITY PROTOCOLS

### Configuration and Environment Protection
- Never commit secrets, API keys, or credentials
- Use environment variables for sensitive configuration
- Validate all external inputs and commands
- Implement proper file permissions and access controls
- Scan for common injection vulnerabilities

### Shell Script Security
- Validate and sanitize all user inputs
- Use proper quoting to prevent injection
- Avoid `eval` and similar dangerous constructs
- Implement proper error handling and logging
- Use secure temporary file creation

## 🎯 QUALITY ASSURANCE

### Pre-Commit Checklist
- [ ] All tests pass locally
- [ ] No secrets or credentials committed
- [ ] Documentation updated
- [ ] Cross-platform compatibility verified
- [ ] Error handling implemented
- [ ] Code follows project conventions
- [ ] **GitHub Actions workflows pass (MANDATORY)**

### Testing Requirements
- Test setup procedures on clean environments
- Validate cross-platform compatibility
- Test error conditions and edge cases
- Verify security measures are effective
- Confirm user experience is intuitive

## 📚 DEVELOPMENT GUIDELINES

### Code Style
- Follow existing project conventions
- Use consistent naming patterns
- Implement comprehensive error handling
- Add meaningful comments for complex logic
- Maintain clean, readable code structure

### Documentation Standards
- Keep README files current and accurate
- Document all configuration options
- Provide clear setup instructions
- Include troubleshooting guidance
- Maintain changelog for releases

### Git Workflow
- Use descriptive commit messages
- Keep commits focused and atomic
- Test before committing
- Update documentation with changes
- Follow branching strategy consistently

---

This cognitive enhancement system is designed to provide intelligent, context-aware assistance for the claude-ally CLI tool project, with emphasis on security, user experience, and maintainability.