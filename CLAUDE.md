# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**Claude-Ally** is a modular, tested, configurable Bash/Shell CLI tool designed to detect and analyze project technology stacks. It provides developers with intelligent project analysis, contributing new stack detection modules, and performance monitoring capabilities.

**Detected Stack**: Bash/Shell CLI Tool, Modular, Tested, CI/CD, Configurable
**Confidence Level**: 150%

## Core Architecture

### Technology Stack
- **Primary Language**: Bash/Shell scripting (Bash 4.0+ compatibility)
- **Architecture**: Modular design with pluggable stack detection modules
- **Testing Framework**: Custom Bash testing framework with comprehensive test suites
- **CI/CD**: GitHub Actions with cross-platform testing (Ubuntu, macOS)
- **Configuration**: JSON-based configuration management with caching system

### Key Components
- **Main CLI**: `claude-ally.sh` - Primary command-line interface
- **Stack Detection**: `stack-detector.sh` - Core detection engine with pluggable modules
- **Stack Modules**: `stacks/` directory with individual detection modules
- **Configuration**: `config-manager.sh` - Settings and cache management
- **Error Handling**: `error-handler.sh` - Comprehensive error recovery system
- **Performance**: `performance-monitor.sh` - System monitoring and optimization

## Development Patterns

### Code Structure Patterns
- **Modular Design**: Break functionality into separate shell scripts in `stacks/` directory
- **Error Handling**: Implement comprehensive error trapping and validation using `error-handler.sh`
- **Configuration Management**: Use JSON config files for user preferences via `config-manager.sh`
- **Help System**: Provide detailed usage and help information for all commands

### Security Patterns
- **Input Validation**: Sanitize all user inputs and file paths
- **Permission Checks**: Verify file permissions before operations
- **Secure Temp Files**: Use proper temporary file creation
- **No Secret Exposure**: Never log or display sensitive information

### Testing Patterns
- **Unit Testing**: Test individual functions with bash test frameworks in `tests/unit/`
- **Integration Testing**: Test CLI commands and workflows in `tests/integration/`
- **Cross-Platform Testing**: Ensure compatibility across OS platforms (Linux/macOS/Windows Git Bash)
- **Continuous Integration**: Automated testing with GitHub Actions

## Command Usage

### Core Commands
```bash
# Detect project stack
./claude-ally.sh detect [project_path]

# Setup configuration and cache
./claude-ally.sh setup

# Show help and available commands
./claude-ally.sh help

# Display version and features
./claude-ally.sh version

# Validate system installation
./claude-ally.sh validate

# Contribute new stack detection module
./claude-ally.sh contribute

# Manage configuration
./claude-ally.sh config [show|reset]

# Cache management
./claude-ally.sh cache [stats|clean]

# Performance monitoring
./claude-ally.sh performance [monitor|stats|optimize]
```

## Development Requirements

### Mandatory Requirements
- Bash 4.0+ compatibility for cross-platform support
- Proper error handling and exit codes
- Input validation and sanitization
- Help/usage documentation for all commands
- Executable permissions on all shell scripts
- Cross-platform compatibility (Linux/macOS/Windows Git Bash)

### Critical Assets
- Shell scripts (main CLI and modules)
- Configuration files (`~/.claude-ally/config.json`)
- Test suites (unit, integration, end-to-end)
- User data and cache
- CLI binaries and stack detection modules

## Testing Strategy

### Test Structure
```
tests/
├── unit/                    # Unit tests for individual functions
│   ├── test_stack_detector.sh
│   ├── test_config_manager.sh
│   └── test_error_handler.sh
├── integration/             # Integration tests for CLI workflows
│   ├── test_cli_integration.sh
│   └── test_module_loading.sh
├── end-to-end/             # Complete workflow testing
│   └── test_complete_workflows.sh
└── run_all_tests.sh        # Test orchestration script
```

### Running Tests
```bash
# Run all test suites
./tests/run_all_tests.sh

# Run specific test suite
./tests/run_all_tests.sh unit
./tests/run_all_tests.sh integration
./tests/run_all_tests.sh end-to-end

# Run with verbose output
./tests/run_all_tests.sh --verbose

# Run tests in parallel
./tests/run_all_tests.sh --parallel
```

## Contributing Stack Detection Modules

### Module Structure
Create new detection modules in `stacks/` directory following this pattern:

```bash
# stacks/your-stack.sh
detect_your_stack() {
    local project_dir="$1"
    local confidence=0
    local features=()
    local project_type="your-type"

    # Detection logic here
    # Return: "stack-id|tech_stack|project_type|confidence"
}

get_your_stack_patterns() {
    # Return Claude-specific patterns
}

get_your_stack_assets() {
    # Return critical assets list
}

get_your_stack_requirements() {
    # Return mandatory requirements
}
```

### Adding New Modules
1. Create detection module in `stacks/`
2. Add function name to `stack-detector.sh` detection_functions array
3. Add comprehensive unit tests
4. Update documentation
5. Test across multiple platforms

## Common Issues and Solutions

### Known Challenges
- Shell compatibility issues between bash versions
- File permission problems on different platforms
- Path handling issues (spaces, special characters)
- Error handling and proper exit codes
- Performance issues with large datasets
- Security vulnerabilities in input handling
- Cross-platform compatibility challenges

### Solutions
- Use Bash 3.2 compatible syntax for maximum compatibility
- Implement comprehensive permission checking
- Proper quoting and escaping for path handling
- Comprehensive error trapping with `set -eE`
- Caching and optimization for performance
- Input sanitization and validation
- Extensive cross-platform testing

## Configuration Management

### Configuration File Location
- Primary: `~/.claude-ally/config.json`
- Cache: `~/.claude-ally/cache/`
- Logs: `~/.claude-ally/error.log`

### Configuration Structure
```json
{
  "version": "2.0.0",
  "cache": {
    "enabled": true,
    "expiry_days": 7,
    "max_size_mb": 50
  },
  "detection": {
    "confidence_threshold": 50,
    "fallback_to_legacy": true,
    "auto_update_modules": true
  },
  "ui": {
    "colors": true,
    "verbose": false,
    "progress_bars": true
  },
  "performance": {
    "monitor_enabled": true,
    "optimization_enabled": true,
    "parallel_detection": true
  }
}
```

## CI/CD and Automation

### GitHub Actions Workflow
- **Cross-platform testing**: Ubuntu and macOS
- **Comprehensive validation**: System, unit, integration, end-to-end tests
- **Security scanning**: Shellcheck and security validation
- **Performance monitoring**: Detection speed and memory usage
- **Badge integration**: Test status badges in README

### Pre-commit Hooks
- Input validation and security scanning
- Test execution before commits
- Code style and formatting checks
- Performance regression testing

## Performance Optimization

### Monitoring Capabilities
- Detection speed measurement
- Memory usage tracking
- Cache hit rate analysis
- System resource utilization

### Optimization Features
- Intelligent caching system
- Parallel detection processing
- Memory-efficient algorithms
- Progressive result loading

## Security Considerations

- All user inputs are validated and sanitized
- File permissions are verified before operations
- Temporary files use secure creation methods
- No sensitive information is logged or displayed
- Cross-platform security validation
- Regular security scanning with Shellcheck

## Version Information

**Current Version**: 2.0.0
**Features**:
- Modular stack detection architecture
- Comprehensive testing framework
- Configuration management system
- Performance monitoring and optimization
- Error handling and recovery
- Cross-platform compatibility
- CI/CD integration
- Security validation

## Support and Documentation

- **Main Documentation**: README.md
- **Contributing Guide**: docs/CONTRIBUTING.md
- **Issue Reporting**: GitHub Issues
- **Security Reports**: Follow responsible disclosure
- **Feature Requests**: GitHub Discussions

---

*This CLAUDE.md file was generated using claude-ally's own stack detection capabilities, demonstrating the self-awareness and accuracy of the detection system.*