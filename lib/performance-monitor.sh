#!/bin/bash
# Performance Monitoring & Analytics
# Tracks system performance and provides optimization insights

METRICS_DIR="$HOME/.claude-ally/metrics"
METRICS_FILE="$METRICS_DIR/performance.log"

# Initialize metrics directory
init_metrics() {
    mkdir -p "$METRICS_DIR"
    touch "$METRICS_FILE"
}

# Record performance metric
record_metric() {
    local operation="$1"
    local duration="$2"
    local success="$3"
    local details="$4"

    init_metrics

    local timestamp
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')

    local metric_entry="$timestamp|$operation|$duration|$success|$details"
    echo "$metric_entry" >> "$METRICS_FILE"
}

# Time a command execution
time_operation() {
    local operation_name="$1"
    shift
    local command="$@"

    local start_time
    start_time=$(date +%s.%N)

    local result=0
    local output

    if output=$($command 2>&1); then
        result=0
    else
        result=$?
    fi

    local end_time
    end_time=$(date +%s.%N)

    local duration
    duration=$(echo "$end_time - $start_time" | bc -l 2>/dev/null || echo "0")

    local success
    if [[ $result -eq 0 ]]; then
        success="SUCCESS"
    else
        success="FAILURE"
    fi

    record_metric "$operation_name" "$duration" "$success" "exit_code:$result"

    return $result
}

# Get performance statistics
get_performance_stats() {
    local operation="$1"
    local days="${2:-7}"

    init_metrics

    if [[ ! -f "$METRICS_FILE" ]]; then
        echo "No metrics available"
        return 1
    fi

    local cutoff_date
    cutoff_date=$(date -d "$days days ago" '+%Y-%m-%d' 2>/dev/null || date -v-${days}d '+%Y-%m-%d' 2>/dev/null)

    echo "Performance Statistics (last $days days)"
    echo "========================================"

    if [[ -n "$operation" ]]; then
        echo "Operation: $operation"
        local ops_data
        ops_data=$(grep "|$operation|" "$METRICS_FILE" | awk -F'|' '$1 >= "'$cutoff_date'"')
    else
        echo "All operations"
        local ops_data
        ops_data=$(awk -F'|' '$1 >= "'$cutoff_date'"' "$METRICS_FILE")
    fi

    if [[ -z "$ops_data" ]]; then
        echo "No data for specified period"
        return 1
    fi

    # Calculate statistics
    local total_ops
    total_ops=$(echo "$ops_data" | wc -l)

    local successful_ops
    successful_ops=$(echo "$ops_data" | grep "|SUCCESS|" | wc -l)

    local failed_ops
    failed_ops=$(echo "$ops_data" | grep "|FAILURE|" | wc -l)

    local success_rate
    if [[ $total_ops -gt 0 ]]; then
        success_rate=$(echo "scale=2; $successful_ops * 100 / $total_ops" | bc -l 2>/dev/null || echo "0")
    else
        success_rate="0"
    fi

    # Duration statistics
    local durations
    durations=$(echo "$ops_data" | cut -d'|' -f3 | grep -E '^[0-9.]+$')

    if [[ -n "$durations" ]]; then
        local avg_duration
        avg_duration=$(echo "$durations" | awk '{sum+=$1; count++} END {if(count>0) print sum/count; else print 0}')

        local min_duration
        min_duration=$(echo "$durations" | sort -n | head -1)

        local max_duration
        max_duration=$(echo "$durations" | sort -n | tail -1)

        echo ""
        echo "Total operations: $total_ops"
        echo "Successful: $successful_ops"
        echo "Failed: $failed_ops"
        echo "Success rate: $success_rate%"
        echo ""
        echo "Duration (seconds):"
        echo "  Average: $(printf "%.3f" "$avg_duration")"
        echo "  Minimum: $(printf "%.3f" "$min_duration")"
        echo "  Maximum: $(printf "%.3f" "$max_duration")"
    else
        echo ""
        echo "Total operations: $total_ops"
        echo "Successful: $successful_ops"
        echo "Failed: $failed_ops"
        echo "Success rate: $success_rate%"
        echo "Duration data: Not available"
    fi
}

# Show top slowest operations
show_slowest_operations() {
    local limit="${1:-10}"

    init_metrics

    echo "Top $limit Slowest Operations"
    echo "============================"

    if [[ ! -f "$METRICS_FILE" ]]; then
        echo "No metrics available"
        return 1
    fi

    awk -F'|' 'NF>=4 && $3 ~ /^[0-9.]+$/ {print $3 " " $2 " " $1}' "$METRICS_FILE" | \
    sort -rn | \
    head -"$limit" | \
    while read -r duration operation timestamp; do
        printf "%8.3fs  %-20s  %s\n" "$duration" "$operation" "$timestamp"
    done
}

# System resource monitoring
monitor_resources() {
    local operation="$1"

    # Get system info
    local cpu_usage=""
    local memory_usage=""
    local disk_usage=""

    # CPU usage (works on most Unix systems)
    if command -v top &> /dev/null; then
        cpu_usage=$(top -l 1 | grep "CPU usage" | awk '{print $3}' 2>/dev/null || echo "unknown")
    fi

    # Memory usage
    if command -v free &> /dev/null; then
        memory_usage=$(free | grep Mem | awk '{printf "%.1f%%", $3/$2 * 100.0}')
    elif command -v vm_stat &> /dev/null; then
        # macOS
        local page_size=4096
        local total_pages
        total_pages=$(sysctl -n hw.memsize)
        total_pages=$((total_pages / page_size))

        local free_pages
        free_pages=$(vm_stat | grep "Pages free" | awk '{print $3}' | sed 's/\.//')

        local used_percentage
        used_percentage=$(echo "scale=1; (($total_pages - $free_pages) * 100) / $total_pages" | bc -l 2>/dev/null)
        memory_usage="${used_percentage}%"
    fi

    # Disk usage of current directory
    disk_usage=$(df . | tail -1 | awk '{print $5}' 2>/dev/null)

    local resource_info="cpu:$cpu_usage,memory:$memory_usage,disk:$disk_usage"
    record_metric "resource_check" "0" "SUCCESS" "$resource_info"
}

# Generate performance report
generate_performance_report() {
    local output_file="${1:-$METRICS_DIR/performance_report_$(date +%Y%m%d).txt}"

    echo "Generating performance report..."

    {
        echo "Claude-Ally Performance Report"
        echo "Generated: $(date)"
        echo "=============================="
        echo ""

        # Overall statistics
        get_performance_stats "" 30

        echo ""
        echo ""

        # Top operations
        echo "Most Common Operations (last 30 days)"
        echo "====================================="
        awk -F'|' 'NF>=4 {print $2}' "$METRICS_FILE" | \
        sort | uniq -c | sort -rn | head -10 | \
        while read -r count operation; do
            printf "%8d  %s\n" "$count" "$operation"
        done

        echo ""
        echo ""

        # Slowest operations
        show_slowest_operations 15

        echo ""
        echo ""

        # Error analysis
        echo "Recent Errors (last 7 days)"
        echo "==========================="
        local cutoff_date
        cutoff_date=$(date -d "7 days ago" '+%Y-%m-%d' 2>/dev/null || date -v-7d '+%Y-%m-%d' 2>/dev/null)

        grep "|FAILURE|" "$METRICS_FILE" | \
        awk -F'|' '$1 >= "'$cutoff_date'"' | \
        tail -10 | \
        while IFS='|' read -r timestamp operation duration status details; do
            echo "$timestamp: $operation failed ($details)"
        done

    } > "$output_file"

    echo "Report saved to: $output_file"
}

# Clean old metrics
clean_old_metrics() {
    local retention_days="${1:-90}"

    if [[ ! -f "$METRICS_FILE" ]]; then
        echo "No metrics file to clean"
        return 0
    fi

    local cutoff_date
    cutoff_date=$(date -d "$retention_days days ago" '+%Y-%m-%d' 2>/dev/null || date -v-${retention_days}d '+%Y-%m-%d' 2>/dev/null)

    local temp_file
    temp_file=$(mktemp)

    awk -F'|' '$1 >= "'$cutoff_date'"' "$METRICS_FILE" > "$temp_file"
    mv "$temp_file" "$METRICS_FILE"

    echo "Cleaned metrics older than $retention_days days"
}

# Performance monitoring CLI
performance_cli() {
    local action="$1"

    case "$action" in
        "stats")
            get_performance_stats "$2" "$3"
            ;;
        "slowest")
            show_slowest_operations "$2"
            ;;
        "resources")
            monitor_resources "$2"
            ;;
        "report")
            generate_performance_report "$2"
            ;;
        "clean")
            clean_old_metrics "$2"
            ;;
        *)
            echo "Performance monitoring commands:"
            echo "  stats [operation] [days]  - Show performance statistics"
            echo "  slowest [limit]           - Show slowest operations"
            echo "  resources [operation]     - Monitor system resources"
            echo "  report [output_file]      - Generate performance report"
            echo "  clean [retention_days]    - Clean old metrics"
            ;;
    esac
}