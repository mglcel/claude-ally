#!/bin/bash
# Configuration Management System
# Provides centralized configuration for claude-ally

CONFIG_DIR="$HOME/.claude-ally"
CONFIG_FILE="$CONFIG_DIR/config.json"
DEFAULT_CONFIG_FILE="/private/tmp/claude-ally/config.default.json"

# Initialize configuration
init_config() {
    mkdir -p "$CONFIG_DIR"

    # Create default config if it doesn't exist
    if [[ ! -f "$CONFIG_FILE" ]]; then
        create_default_config
    fi
}

# Create default configuration
create_default_config() {
    cat > "$CONFIG_FILE" << 'EOF'
{
  "version": "2.0.0",
  "cache": {
    "enabled": true,
    "expiry_days": 7,
    "max_size_mb": 100
  },
  "detection": {
    "confidence_threshold": 60,
    "fallback_to_legacy": true,
    "auto_update_modules": true
  },
  "github": {
    "auto_fork": true,
    "auto_open_pr": false,
    "default_branch": "main"
  },
  "ui": {
    "colors": true,
    "verbose": false,
    "progress_bars": true
  },
  "telemetry": {
    "enabled": false,
    "anonymous": true
  },
  "modules": {
    "auto_load": true,
    "custom_paths": []
  }
}
EOF
    echo "Created default configuration: $CONFIG_FILE"
}

# Get configuration value
get_config() {
    local key="$1"
    local default_value="$2"

    init_config

    if command -v jq &> /dev/null; then
        local value
        value=$(jq -r ".$key" "$CONFIG_FILE" 2>/dev/null)
        if [[ "$value" != "null" ]] && [[ -n "$value" ]]; then
            echo "$value"
        else
            echo "$default_value"
        fi
    else
        # Fallback parsing without jq
        local value
        value=$(grep "\"$key\"" "$CONFIG_FILE" | sed 's/.*: *"\([^"]*\)".*/\1/' 2>/dev/null)
        echo "${value:-$default_value}"
    fi
}

# Set configuration value
set_config() {
    local key="$1"
    local value="$2"

    init_config

    if command -v jq &> /dev/null; then
        local temp_file
        temp_file=$(mktemp)
        jq ".$key = \"$value\"" "$CONFIG_FILE" > "$temp_file" && mv "$temp_file" "$CONFIG_FILE"
        echo "Updated $key = $value"
    else
        echo "Warning: jq not available, cannot update configuration"
        echo "Please install jq for configuration management"
        return 1
    fi
}

# Show current configuration
show_config() {
    init_config

    echo "Claude-Ally Configuration:"
    echo "=========================="
    echo "Config file: $CONFIG_FILE"
    echo ""

    if command -v jq &> /dev/null; then
        jq '.' "$CONFIG_FILE" | sed 's/^/  /'
    else
        echo "Raw configuration (install jq for formatted display):"
        cat "$CONFIG_FILE" | sed 's/^/  /'
    fi
}

# Configure claude-ally interactively
configure_claude_ally() {
    echo "Claude-Ally Interactive Configuration"
    echo "===================================="
    echo ""

    # Cache settings
    local cache_enabled
    cache_enabled=$(get_config "cache.enabled" "true")
    echo "Current cache enabled: $cache_enabled"
    read -p "Enable caching? (Y/n): " cache_choice
    if [[ "$cache_choice" =~ ^[Nn] ]]; then
        set_config "cache.enabled" "false"
    else
        set_config "cache.enabled" "true"
    fi

    # Detection settings
    local confidence_threshold
    confidence_threshold=$(get_config "detection.confidence_threshold" "60")
    echo ""
    echo "Current confidence threshold: $confidence_threshold"
    read -p "Confidence threshold (50-100): " new_threshold
    if [[ "$new_threshold" =~ ^[0-9]+$ ]] && [[ $new_threshold -ge 50 ]] && [[ $new_threshold -le 100 ]]; then
        set_config "detection.confidence_threshold" "$new_threshold"
    fi

    # GitHub settings
    echo ""
    local auto_fork
    auto_fork=$(get_config "github.auto_fork" "true")
    echo "Current auto-fork: $auto_fork"
    read -p "Automatically fork repositories? (Y/n): " fork_choice
    if [[ "$fork_choice" =~ ^[Nn] ]]; then
        set_config "github.auto_fork" "false"
    else
        set_config "github.auto_fork" "true"
    fi

    # UI settings
    echo ""
    local colors_enabled
    colors_enabled=$(get_config "ui.colors" "true")
    echo "Current colors: $colors_enabled"
    read -p "Enable colored output? (Y/n): " color_choice
    if [[ "$color_choice" =~ ^[Nn] ]]; then
        set_config "ui.colors" "false"
    else
        set_config "ui.colors" "true"
    fi

    echo ""
    echo "Configuration updated successfully!"
    echo "Use 'claude-ally config show' to view current settings"
}

# Reset configuration to defaults
reset_config() {
    echo "Resetting claude-ally configuration to defaults..."
    rm -f "$CONFIG_FILE"
    create_default_config
    echo "Configuration reset completed"
}

# Migrate old configuration
migrate_config() {
    local old_config="$CONFIG_DIR/.clauderc"

    if [[ -f "$old_config" ]] && [[ ! -f "$CONFIG_FILE" ]]; then
        echo "Migrating old configuration..."
        # Simple migration logic here
        create_default_config
        echo "Migration completed. Old config backed up to: $old_config.bak"
        mv "$old_config" "$old_config.bak"
    fi
}

# Validate configuration
validate_config() {
    init_config

    if command -v jq &> /dev/null; then
        if jq empty "$CONFIG_FILE" 2>/dev/null; then
            echo "✅ Configuration valid"
            return 0
        else
            echo "❌ Configuration invalid JSON"
            echo "💡 Run 'claude-ally config reset' to fix"
            return 1
        fi
    else
        echo "⚠️ Cannot validate without jq, but file exists"
        return 0
    fi
}

# Configuration CLI interface
config_cli() {
    local action="$1"

    case "$action" in
        "show"|"")
            show_config
            ;;
        "set")
            if [[ $# -lt 3 ]]; then
                echo "Usage: config set <key> <value>"
                exit 1
            fi
            set_config "$2" "$3"
            ;;
        "get")
            if [[ $# -lt 2 ]]; then
                echo "Usage: config get <key> [default]"
                exit 1
            fi
            get_config "$2" "$3"
            ;;
        "configure")
            configure_claude_ally
            ;;
        "reset")
            reset_config
            ;;
        "validate")
            validate_config
            ;;
        "migrate")
            migrate_config
            ;;
        *)
            echo "Unknown config action: $action"
            echo "Available actions: show, set, get, configure, reset, validate, migrate"
            exit 1
            ;;
    esac
}