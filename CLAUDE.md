# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is the **Claude-Ally Universal Cognitive Enhancement System** - a production-ready enterprise tool for enhancing Claude conversations with intelligent project analysis, modular stack detection, and automated setup workflows.

**Project Type**: CLI Tool / Developer Utility
**Tech Stack**: Bash/Shell CLI Tool, Modular Architecture, Comprehensive Testing, CI/CD
**Critical Assets**: Cognitive enhancement prompts, user project configurations, stack detection modules
**Deployment Target**: Developer workstations, CI/CD pipelines

## 🚀 Development Guidelines

### Shell Scripting Best Practices
- **Security**: Always validate inputs, sanitize user data, use secure defaults
- **Error Handling**: Implement comprehensive error trapping with meaningful messages
- **Modularity**: Keep functions focused and reusable across the lib/ directory
- **Testing**: Every shell function must have corresponding unit tests
- **Cross-Platform**: Ensure compatibility across Linux, macOS, and Windows (WSL)

### Project Architecture
```
claude-ally/
├── lib/              # Core shell modules (error handling, progress, stack detection)
├── stacks/           # Modular stack detection engines (nextjs-ai, python-ai, etc.)
├── tests/            # Comprehensive test suite (unit, integration, e2e)
├── .github/          # CI/CD workflows with cross-platform testing
└── docs/             # Documentation and team collaboration protocols
```

### Key Development Patterns

#### 1. Progress Indication
Always provide visual feedback for long-running operations:
```bash
if declare -f start_progress > /dev/null; then
    start_progress "Detecting project stack" "spinner"
fi
# ... operation ...
if declare -f stop_progress > /dev/null; then
    stop_progress
fi
```

#### 2. Error Handling
Use the centralized error handling system:
```bash
if ! some_operation; then
    if declare -f show_error > /dev/null; then
        show_error "Operation failed"
    else
        echo -e "${RED}❌ Operation failed${NC}"
    fi
    return 1
fi
```

#### 3. Stack Detection
Follow the modular detection pattern:
```bash
detect_my_stack() {
    local project_dir="$1"
    # Detection logic here
    if [[ condition ]]; then
        echo "stack-id|Tech Stack Name|project-type|confidence"
        return 0
    fi
    return 1
}
```

### Testing Requirements
- **Unit Tests**: Every function in lib/ must have unit tests
- **Integration Tests**: Test CLI workflows end-to-end
- **Cross-Platform**: Validate on Ubuntu and macOS via GitHub Actions
- **Performance**: Monitor operation timing and optimize slow paths

### Security Considerations
- **Input Validation**: All user inputs must be validated and sanitized
- **File Permissions**: Scripts must check and set appropriate permissions
- **Secret Handling**: Never log or expose sensitive configuration data
- **Command Injection**: Use proper quoting and parameter expansion

### Common Issues & Solutions
- **Prompt Customization Complexity**: Use the modular configuration system
- **Setup Time**: Leverage caching and parallel processing where possible
- **Cross-Platform Compatibility**: Test extensively on target platforms
- **Stack Detection Accuracy**: Continuously improve detection algorithms

## 🧠 Cognitive Enhancement Patterns

### When Working on Stack Detection
- Analyze file patterns comprehensively (package.json, requirements.txt, etc.)
- Consider framework combinations and modern toolchains
- Implement confidence scoring based on multiple indicators
- Test with real-world project structures

### When Improving User Experience
- Prioritize clear visual feedback and progress indication
- Implement intelligent defaults based on project analysis
- Provide helpful error messages with actionable guidance
- Ensure consistent experience across all CLI commands

### When Adding New Features
- Follow the modular architecture in lib/ directory
- Add comprehensive tests before implementation
- Update documentation and help text
- Consider cross-platform implications

### When Debugging Issues
- Use the error logging system in ~/.claude-ally/error.log
- Implement verbose modes for detailed diagnostics
- Test with edge cases and malformed inputs
- Validate on multiple operating systems

## 🔧 Development Workflow

1. **Feature Development**: Implement in lib/ with proper error handling
2. **Testing**: Add unit tests and integration tests
3. **Documentation**: Update help text and README
4. **Validation**: Run full test suite and cross-platform checks
5. **CI/CD**: Ensure GitHub Actions workflows pass
6. **Performance**: Monitor timing and optimize critical paths

## 🚀 Enhancement Priorities

- **Intelligence**: Improve stack detection accuracy and coverage
- **Performance**: Optimize slow operations and add caching
- **User Experience**: Enhance visual feedback and error messages
- **Compatibility**: Ensure broad platform and shell support
- **Modularity**: Make components easily extensible and testable

---

**Built for developers, by developers. Enhancing Claude conversations with intelligent project analysis.**