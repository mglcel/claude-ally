#!/bin/bash
# Cordova Hybrid App Stack Detection
# Detects Cordova/PhoneGap hybrid mobile applications

detect_cordova() {
    local project_dir="$1"
    local confidence=0
    local tech_stack=""
    local project_type=""

    # Check for Cordova configuration
    if [[ -f "$project_dir/config.xml" ]]; then
        confidence=$((confidence + 40))
        tech_stack="JavaScript/Cordova"
        project_type="cordova-hybrid-app"
    fi

    # Check for Cordova directory structure
    if [[ -d "$project_dir/www" ]]; then
        confidence=$((confidence + 20))
    fi

    if [[ -d "$project_dir/platforms" ]] || [[ -d "$project_dir/plugins" ]]; then
        confidence=$((confidence + 15))
    fi

    # Check for Cordova dependencies in package.json
    if [[ -f "$project_dir/package.json" ]]; then
        local cordova_patterns=("cordova-" "phonegap" "@cordova")

        for pattern in "${cordova_patterns[@]}"; do
            if grep -q "$pattern" "$project_dir/package.json"; then
                confidence=$((confidence + 20))
                break
            fi
        done

        # Check for maps integration
        local maps_patterns=("mapbox" "leaflet" "google-maps" "openlayers" "arcgis")
        for pattern in "${maps_patterns[@]}"; do
            if grep -q -i "$pattern" "$project_dir/package.json"; then
                tech_stack="$tech_stack, Maps"
                confidence=$((confidence + 10))
                break
            fi
        done
    fi

    # Check for Cordova CLI configuration
    if [[ -f "$project_dir/.cordova/config.json" ]]; then
        confidence=$((confidence + 10))
    fi

    # Minimum confidence threshold
    if [[ $confidence -ge 50 ]]; then
        echo "cordova|$tech_stack|$project_type|$confidence"
        return 0
    fi

    return 1
}

get_cordova_patterns() {
    cat << 'EOF'
CORDOVA HYBRID APP PATTERNS
Cordova_Hybrid_Patterns (HIGH - Cross-Platform & Performance):
  CRITICAL_CORDOVA:
    - "Plugin", "native", "bridge" → Native integration security
    - "Device", "permission", "capability" → Device access validation
    - "Offline", "storage", "sync" → Data management and synchronization
  HIGH_PRIORITY:
    - "Performance", "memory", "battery" → Mobile performance optimization
    - "Update", "deployment", "versioning" → App lifecycle management
    - "CSP", "whitelist", "security" → Mobile security policies
EOF
}

get_cordova_assets() {
    echo "native plugins, device data, offline storage, user credentials, app signing certificates"
}

get_cordova_requirements() {
    echo "mobile security policies, offline functionality, cross-platform compatibility, app store compliance"
}

get_cordova_issues() {
    echo "plugin compatibility, performance bottlenecks, memory leaks, platform-specific behaviors, app store approval"
}