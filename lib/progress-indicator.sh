#!/bin/bash
# Progress Indicator & Loading Animation System
# Provides visual feedback for long-running operations with configurable styles

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

# Progress indicator configuration
PROGRESS_ENABLED=true
PROGRESS_STYLE="spinner"  # spinner, dots, bar, minimal
PROGRESS_SPEED=0.1
PROGRESS_WIDTH=50

# Initialize progress configuration from config manager
init_progress_config() {
    if command -v get_config_value &> /dev/null; then
        PROGRESS_ENABLED=$(get_config_value "ui.progress_bars" "true")
        PROGRESS_STYLE=$(get_config_value "ui.progress_style" "spinner")
    fi
}

# Spinner animation frames
SPINNER_FRAMES=('⠋' '⠙' '⠹' '⠸' '⠼' '⠴' '⠦' '⠧' '⠇' '⠏')
DOTS_FRAMES=('.' '..' '...' '....' '...' '..' '.')
BAR_CHARS=('▏' '▎' '▍' '▌' '▋' '▊' '▉' '█')

# Progress state variables
PROGRESS_PID=""
PROGRESS_ACTIVE=false
PROGRESS_MESSAGE=""
PROGRESS_START_TIME=""

# Show spinner animation
show_spinner() {
    local message="$1"
    local frame_index=0

    while true; do
        printf "\r${CYAN}${SPINNER_FRAMES[frame_index]}${NC} $message"
        frame_index=$(( (frame_index + 1) % ${#SPINNER_FRAMES[@]} ))
        sleep $PROGRESS_SPEED
    done
}

# Show dots animation
show_dots() {
    local message="$1"
    local frame_index=0

    while true; do
        printf "\r${CYAN}$message${DOTS_FRAMES[frame_index]}${NC}   "
        frame_index=$(( (frame_index + 1) % ${#DOTS_FRAMES[@]} ))
        sleep $(echo "$PROGRESS_SPEED * 2" | bc 2>/dev/null || echo "0.2")
    done
}

# Show progress bar (for operations with known progress)
show_progress_bar() {
    local current="$1"
    local total="$2"
    local message="$3"

    if [[ $total -eq 0 ]]; then
        return
    fi

    local percentage=$((current * 100 / total))
    local filled=$((current * PROGRESS_WIDTH / total))
    local empty=$((PROGRESS_WIDTH - filled))

    local bar=""
    for ((i=0; i<filled; i++)); do
        bar+="█"
    done
    for ((i=0; i<empty; i++)); do
        bar+="░"
    done

    printf "\r${CYAN}[$bar]${NC} $percentage%% $message"
}

# Show minimal progress (just message with elapsed time)
show_minimal() {
    local message="$1"
    local start_time="$2"

    while true; do
        local current_time=$(date +%s)
        local elapsed=$((current_time - start_time))
        printf "\r${CYAN}●${NC} $message (${elapsed}s)"
        sleep 1
    done
}

# Start progress indicator
start_progress() {
    local message="$1"
    local style="${2:-$PROGRESS_STYLE}"

    # Check if progress is disabled
    if [[ "$PROGRESS_ENABLED" != "true" ]]; then
        echo "$message"
        return
    fi

    # Stop any existing progress
    stop_progress 2>/dev/null

    PROGRESS_MESSAGE="$message"
    PROGRESS_START_TIME=$(date +%s)
    PROGRESS_ACTIVE=true

    case "$style" in
        "spinner")
            show_spinner "$message" &
            ;;
        "dots")
            show_dots "$message" &
            ;;
        "minimal")
            show_minimal "$message" "$PROGRESS_START_TIME" &
            ;;
        *)
            # Default to spinner
            show_spinner "$message" &
            ;;
    esac

    PROGRESS_PID=$!
}

# Update progress bar (for known progress operations)
update_progress() {
    local current="$1"
    local total="$2"
    local message="${3:-$PROGRESS_MESSAGE}"

    if [[ "$PROGRESS_ENABLED" != "true" ]]; then
        return
    fi

    show_progress_bar "$current" "$total" "$message"
}

# Stop progress indicator
stop_progress() {
    if [[ -n "$PROGRESS_PID" ]]; then
        # Use a more gentle termination
        kill -TERM "$PROGRESS_PID" 2>/dev/null || true
        sleep 0.1
        # Force kill if still running
        kill -KILL "$PROGRESS_PID" 2>/dev/null || true
        wait "$PROGRESS_PID" 2>/dev/null || true
        PROGRESS_PID=""
    fi

    if [[ "$PROGRESS_ACTIVE" == "true" ]]; then
        printf "\r\033[K"  # Clear the line
        PROGRESS_ACTIVE=false
    fi
}

# Show success message after operation
show_success() {
    local message="$1"
    local elapsed=""

    if [[ -n "$PROGRESS_START_TIME" ]]; then
        local end_time=$(date +%s)
        elapsed=" ($(( end_time - PROGRESS_START_TIME ))s)"
    fi

    echo -e "${GREEN}✅${NC} $message$elapsed"
}

# Show error message after operation
show_error() {
    local message="$1"
    local elapsed=""

    if [[ -n "$PROGRESS_START_TIME" ]]; then
        local end_time=$(date +%s)
        elapsed=" ($(( end_time - PROGRESS_START_TIME ))s)"
    fi

    echo -e "${RED}❌${NC} $message$elapsed"
}

# Show warning message
show_warning() {
    local message="$1"
    echo -e "${YELLOW}⚠️${NC} $message"
}

# Show info message
show_info() {
    local message="$1"
    echo -e "${BLUE}ℹ️${NC} $message"
}

# Progress wrapper for commands
with_progress() {
    local message="$1"
    local style="${2:-spinner}"
    shift 2
    local command="$@"

    start_progress "$message" "$style"

    # Execute the command
    if eval "$command" >/dev/null 2>&1; then
        stop_progress
        show_success "$message completed"
        return 0
    else
        local exit_code=$?
        stop_progress
        show_error "$message failed"
        return $exit_code
    fi
}

# Progress wrapper for commands with output capture
with_progress_output() {
    local message="$1"
    local style="${2:-spinner}"
    shift 2
    local command="$@"

    start_progress "$message" "$style"

    # Execute the command and capture output
    local output
    local exit_code

    if output=$(eval "$command" 2>&1); then
        exit_code=0
        stop_progress
        show_success "$message completed"
        echo "$output"
    else
        exit_code=$?
        stop_progress
        show_error "$message failed"
        echo "$output" >&2
    fi

    return $exit_code
}

# Multi-step progress for complex operations
start_multi_step() {
    local total_steps="$1"
    local operation_name="$2"

    echo -e "${BOLD}$operation_name${NC}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

    export MULTI_STEP_TOTAL="$total_steps"
    export MULTI_STEP_CURRENT=0
    export MULTI_STEP_NAME="$operation_name"
}

# Execute a step in multi-step operation
execute_step() {
    local step_name="$1"
    shift
    local command="$@"

    MULTI_STEP_CURRENT=$((MULTI_STEP_CURRENT + 1))

    local step_prefix="[$MULTI_STEP_CURRENT/$MULTI_STEP_TOTAL]"

    start_progress "$step_prefix $step_name"

    if eval "$command" >/dev/null 2>&1; then
        stop_progress
        echo -e "$step_prefix ${GREEN}✅${NC} $step_name"
        return 0
    else
        local exit_code=$?
        stop_progress
        echo -e "$step_prefix ${RED}❌${NC} $step_name"
        return $exit_code
    fi
}

# Finish multi-step operation
finish_multi_step() {
    local success="${1:-true}"

    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

    if [[ "$success" == "true" ]]; then
        echo -e "${GREEN}🎉 $MULTI_STEP_NAME completed successfully${NC}"
    else
        echo -e "${RED}💥 $MULTI_STEP_NAME failed${NC}"
    fi

    unset MULTI_STEP_TOTAL MULTI_STEP_CURRENT MULTI_STEP_NAME
}

# File operation progress (for scanning directories, etc.)
scan_with_progress() {
    local directory="$1"
    local pattern="$2"
    local message="${3:-Scanning files}"

    if [[ "$PROGRESS_ENABLED" != "true" ]]; then
        find "$directory" -name "$pattern" 2>/dev/null
        return
    fi

    start_progress "$message"

    local files
    files=$(find "$directory" -name "$pattern" 2>/dev/null)

    stop_progress
    show_success "$message completed"

    echo "$files"
}

# Long operation with periodic updates
long_operation_with_updates() {
    local operation_name="$1"
    local duration="$2"  # in seconds
    shift 2
    local command="$@"

    start_progress "$operation_name"

    # Start the actual command in background
    eval "$command" &
    local cmd_pid=$!

    # Monitor progress
    local elapsed=0
    while kill -0 "$cmd_pid" 2>/dev/null; do
        sleep 1
        elapsed=$((elapsed + 1))

        # Update progress message with elapsed time
        if [[ "$PROGRESS_ACTIVE" == "true" ]]; then
            stop_progress
            start_progress "$operation_name (${elapsed}s)"
        fi
    done

    # Wait for command to complete and get exit code
    wait "$cmd_pid"
    local exit_code=$?

    stop_progress

    if [[ $exit_code -eq 0 ]]; then
        show_success "$operation_name completed"
    else
        show_error "$operation_name failed"
    fi

    return $exit_code
}

# Cleanup function for script exit
cleanup_progress() {
    if [[ "$PROGRESS_ACTIVE" == "true" ]]; then
        stop_progress 2>/dev/null || true
    fi
}

# Set up cleanup on script exit (but don't override existing traps)
if [[ -z "${CLAUDE_ALLY_TRAP_SET:-}" ]]; then
    trap cleanup_progress EXIT INT TERM
    export CLAUDE_ALLY_TRAP_SET=true
fi

# Configuration functions
enable_progress() {
    PROGRESS_ENABLED=true
}

disable_progress() {
    PROGRESS_ENABLED=false
    stop_progress
}

set_progress_style() {
    local style="$1"
    case "$style" in
        "spinner"|"dots"|"bar"|"minimal")
            PROGRESS_STYLE="$style"
            ;;
        *)
            echo "Invalid progress style: $style. Valid options: spinner, dots, bar, minimal"
            return 1
            ;;
    esac
}

# Export functions for use in other scripts
if [[ "${BASH_SOURCE[0]}" != "${0}" ]]; then
    export -f init_progress_config
    export -f start_progress stop_progress
    export -f show_success show_error show_warning show_info
    export -f with_progress with_progress_output
    export -f start_multi_step execute_step finish_multi_step
    export -f scan_with_progress long_operation_with_updates
    export -f enable_progress disable_progress set_progress_style
    export -f update_progress
fi