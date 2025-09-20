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

1. **Detects your tech stack** - Analyzes your project files (package.json, requirements.txt, etc.)
2. **Creates a CLAUDE.md file** - Contains your project context and requirements
3. **Claude reads this context** - Gives responses specific to your setup

## Supported Stacks

- **Frontend**: React, Vue, Angular, Next.js
- **Backend**: Node.js, Python (Django/FastAPI), Go, Java Spring
- **Mobile**: React Native, Flutter, Cordova
- **Databases**: PostgreSQL, MySQL, MongoDB, Redis
- **Cloud**: AWS, Azure, GCP patterns

## Commands

```bash
claude-ally.sh setup      # Configure Claude for your project
claude-ally.sh detect     # See what tech stack was detected
claude-ally.sh contribute # Add your stack to the community
claude-ally.sh help       # Show all commands
```

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
- Claude CLI (optional, for automatic setup)

## License

Apache License 2.0 - see [LICENSE](LICENSE) file for details.

---

Transform your Claude conversations from generic to project-specific in 30 seconds.