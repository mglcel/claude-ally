#!/bin/bash
# Claude Analysis Cache Manager
# Optimizes performance by caching Claude analysis results

CACHE_DIR="$HOME/.claude-ally/cache"
CACHE_EXPIRY_DAYS=7

# Initialize cache directory
init_cache() {
    mkdir -p "$CACHE_DIR"
    touch "$CACHE_DIR/.gitignore"
    echo "# Claude-ally analysis cache" > "$CACHE_DIR/.gitignore"
    echo "*.md" >> "$CACHE_DIR/.gitignore"
}

# Generate cache key from project characteristics
generate_cache_key() {
    local project_dir="$1"
    local key_components=""

    # Include key files in hash
    for file in "package.json" "requirements.txt" "pubspec.yaml" "Cargo.toml" "go.mod"; do
        if [[ -f "$project_dir/$file" ]]; then
            key_components+=$(head -20 "$project_dir/$file" | grep -E "(name|dependencies|version)" | sort)
        fi
    done

    # Include directory structure signature
    key_components+=$(find "$project_dir" -maxdepth 2 -type f -name "*.config.*" -o -name "*.json" -o -name "*.toml" | sort)

    # Generate hash
    echo "$key_components" | sha256sum | cut -d' ' -f1
}

# Check if cached analysis exists and is valid
get_cached_analysis() {
    local cache_key="$1"
    local cache_file="$CACHE_DIR/${cache_key}.md"

    if [[ -f "$cache_file" ]]; then
        # Check if cache is not expired
        local cache_age
        cache_age=$(find "$cache_file" -mtime +$CACHE_EXPIRY_DAYS 2>/dev/null)

        if [[ -z "$cache_age" ]]; then
            echo "CACHE_HIT"
            cat "$cache_file"
            return 0
        else
            rm -f "$cache_file"  # Remove expired cache
        fi
    fi

    echo "CACHE_MISS"
    return 1
}

# Store analysis result in cache
store_cached_analysis() {
    local cache_key="$1"
    local analysis_result="$2"
    local cache_file="$CACHE_DIR/${cache_key}.md"

    init_cache
    echo "$analysis_result" > "$cache_file"
    echo "CACHE_STORED: $cache_file"
}

# Clean old cache entries
clean_cache() {
    if [[ -d "$CACHE_DIR" ]]; then
        find "$CACHE_DIR" -name "*.md" -mtime +$CACHE_EXPIRY_DAYS -delete
        echo "Cache cleaned: removed entries older than $CACHE_EXPIRY_DAYS days"
    fi
}

# Get cache statistics
cache_stats() {
    if [[ -d "$CACHE_DIR" ]]; then
        local total_entries
        local cache_size
        total_entries=$(find "$CACHE_DIR" -name "*.md" | wc -l)
        cache_size=$(du -sh "$CACHE_DIR" 2>/dev/null | cut -f1)

        echo "Cache Statistics:"
        echo "  Location: $CACHE_DIR"
        echo "  Entries: $total_entries"
        echo "  Size: $cache_size"
        echo "  Expiry: $CACHE_EXPIRY_DAYS days"
    else
        echo "Cache not initialized"
    fi
}