# Claude-Ally

[![Tests](https://github.com/mglcel/claude-ally/actions/workflows/test-fixed.yml/badge.svg)](https://github.com/mglcel/claude-ally/actions/workflows/test-fixed.yml)
[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](https://opensource.org/licenses/Apache-2.0)

**Automatically configure Claude with your project's tech stack for better, more relevant responses.**

## Quick Start

```bash
# Clone the repository
git clone https://github.com/mglcel/claude-ally.git

# Go to your project directory
cd /path/to/your/project

# Set up Claude with your project context
/path/to/claude-ally/claude-ally.sh setup
```

That's it! Claude will now understand your project structure and give more relevant advice.

## What It Does

**Before Claude-Ally:**
- "How do I add authentication?" → Generic authentication advice
- "What's the best way to structure this?" → Generic patterns

**After Claude-Ally:**
- "How do I add authentication?" → React + Node.js specific auth with JWT, proper error handling, and security best practices
- "What's the best way to structure this?" → Advice tailored to your exact tech stack

## How It Works

1. **Intelligently analyzes your project** - Uses Claude AI to examine your project structure and files
2. **Detects your exact tech stack** - Goes beyond simple file patterns to understand your architecture
3. **Automatically creates CLAUDE.md** - Generates comprehensive project context using Claude
4. **Enhanced Claude conversations** - All future Claude interactions use your project-specific context

## Commands

```bash
claude-ally.sh setup      # Auto-configure Claude with AI analysis
claude-ally.sh clean      # Clean project-specific caches
claude-ally.sh detect     # See what tech stack was detected
claude-ally.sh analyze    # Comprehensive project analysis
claude-ally.sh contribute # Add your stack to the community
claude-ally.sh validate   # Validate system installation
claude-ally.sh help       # Show all commands
```

### New in v2.2
- **🤖 Real Claude Integration**: Automatic CLAUDE.md generation using Claude AI analysis
- **🔍 Intelligent Stack Detection**: Claude-powered project analysis beyond static file patterns
- **🧹 Project-Specific Caching**: New `clean` command for targeted cache management
- **⚡ Prioritized Analysis**: Claude analysis → static detection → generic fallback hierarchy
- **🛡️ Enhanced Security Patterns**: Comprehensive PHP Laravel support with security best practices
- **🔧 Improved Error Handling**: Better Claude CLI availability detection and fallbacks

## Example

For a React + Node.js project, Claude will automatically know to:
- Suggest React hooks and component patterns
- Recommend Express middleware and error handling
- Include security considerations for web apps
- Use your specific database patterns

## Contributing

Found a missing tech stack? Run:
```bash
claude-ally.sh contribute
```

This analyzes your project and helps add it to the community stack library.

## Requirements

- Bash shell (Linux, macOS, Windows with WSL)
- Git (for contributing new stacks)
- Claude Code CLI (recommended, enables automatic CLAUDE.md generation)

## License

Apache License 2.0 - see [LICENSE](LICENSE) file for details.

---

Transform your Claude conversations from generic to project-specific in 30 seconds.