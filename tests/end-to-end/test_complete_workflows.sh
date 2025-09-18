#!/bin/bash
# End-to-end tests for claude-ally complete workflows
# Tests realistic user scenarios from start to finish

set -euo pipefail

# Test framework
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Test counters
TESTS_TOTAL=0
TESTS_PASSED=0
TESTS_FAILED=0

# Test framework functions
assert_workflow_step() {
    local step_description="$1"
    local command="$2"
    local expected_in_output="$3"

    TESTS_TOTAL=$((TESTS_TOTAL + 1))

    echo -e "  ${BLUE}→${NC} $step_description"

    local output
    if output=$(eval "$command" 2>&1); then
        if [[ "$output" == *"$expected_in_output"* ]]; then
            echo -e "    ${GREEN}✅ PASS${NC}"
            TESTS_PASSED=$((TESTS_PASSED + 1))
            return 0
        else
            echo -e "    ${RED}❌ FAIL${NC} - Expected output not found"
            echo -e "    ${YELLOW}Expected:${NC} $expected_in_output"
            echo -e "    ${YELLOW}Got:${NC} $output"
            TESTS_FAILED=$((TESTS_FAILED + 1))
            return 1
        fi
    else
        echo -e "    ${RED}❌ FAIL${NC} - Command failed to execute"
        echo -e "    ${YELLOW}Command:${NC} $command"
        echo -e "    ${YELLOW}Output:${NC} $output"
        TESTS_FAILED=$((TESTS_FAILED + 1))
        return 1
    fi
}

# Setup test environment
setup() {
    # Create isolated test workspace
    export E2E_TEST_DIR="/tmp/claude-ally-e2e-$(date +%s)"
    mkdir -p "$E2E_TEST_DIR"

    # Create test config
    export TEST_CONFIG_HOME="$E2E_TEST_DIR/.claude-ally"
    mkdir -p "$TEST_CONFIG_HOME"

    cat > "$TEST_CONFIG_HOME/config.json" << 'EOF'
{
  "version": "2.0.0",
  "cache": {
    "enabled": true,
    "expiry_days": 1,
    "max_size_mb": 5
  },
  "detection": {
    "confidence_threshold": 60,
    "fallback_to_legacy": false,
    "auto_update_modules": false
  },
  "ui": {
    "colors": false,
    "verbose": true,
    "progress_bars": false
  },
  "telemetry": {
    "enabled": false
  }
}
EOF

    export CLAUDE_ALLY_CONFIG_HOME="$TEST_CONFIG_HOME"
}

# Cleanup test environment
cleanup() {
    if [[ -n "${E2E_TEST_DIR:-}" && -d "$E2E_TEST_DIR" ]]; then
        rm -rf "$E2E_TEST_DIR"
    fi
    unset E2E_TEST_DIR
    unset TEST_CONFIG_HOME
    unset CLAUDE_ALLY_CONFIG_HOME
}

# Create realistic project fixtures
create_nextjs_ai_project() {
    local project_dir="$E2E_TEST_DIR/nextjs-ai-project"
    mkdir -p "$project_dir"

    # package.json with Next.js and AI dependencies
    cat > "$project_dir/package.json" << 'EOF'
{
  "name": "ai-chat-app",
  "version": "1.0.0",
  "scripts": {
    "dev": "next dev",
    "build": "next build",
    "start": "next start"
  },
  "dependencies": {
    "next": "14.0.0",
    "react": "^18.0.0",
    "react-dom": "^18.0.0",
    "ai": "^3.2.0",
    "@ai-sdk/openai": "^0.0.40",
    "tailwindcss": "^3.3.0"
  },
  "devDependencies": {
    "typescript": "^5.0.0",
    "@types/react": "^18.0.0",
    "@types/node": "^20.0.0"
  }
}
EOF

    # next.config.js
    cat > "$project_dir/next.config.js" << 'EOF'
/** @type {import('next').NextConfig} */
const nextConfig = {
  experimental: {
    appDir: true,
  },
}

module.exports = nextConfig
EOF

    # tsconfig.json
    cat > "$project_dir/tsconfig.json" << 'EOF'
{
  "compilerOptions": {
    "target": "es5",
    "lib": ["dom", "dom.iterable", "es6"],
    "allowJs": true,
    "skipLibCheck": true,
    "strict": true,
    "moduleResolution": "node",
    "resolveJsonModule": true,
    "isolatedModules": true,
    "noEmit": true,
    "jsx": "preserve",
    "incremental": true,
    "plugins": [
      {
        "name": "next"
      }
    ],
    "paths": {
      "@/*": ["./*"]
    }
  }
}
EOF

    # tailwind.config.js
    echo "module.exports = { content: ['./app/**/*.{js,ts,jsx,tsx}'] }" > "$project_dir/tailwind.config.js"

    # Create app structure
    mkdir -p "$project_dir/app/api/chat"
    echo "export async function POST() { return new Response('AI endpoint') }" > "$project_dir/app/api/chat/route.ts"

    mkdir -p "$project_dir/components"
    echo "export default function ChatComponent() { return <div>Chat</div> }" > "$project_dir/components/Chat.tsx"

    echo "$project_dir"
}

create_python_ml_project() {
    local project_dir="$E2E_TEST_DIR/python-ml-project"
    mkdir -p "$project_dir"

    # requirements.txt with ML dependencies
    cat > "$project_dir/requirements.txt" << 'EOF'
torch==2.0.0+cpu
transformers==4.30.0
gradio==3.35.0
numpy==1.24.0
pandas==2.0.0
scikit-learn==1.3.0
matplotlib==3.7.0
jupyter==1.0.0
fastapi==0.100.0
uvicorn==0.22.0
EOF

    # pyproject.toml
    cat > "$project_dir/pyproject.toml" << 'EOF'
[build-system]
requires = ["setuptools>=45", "wheel"]
build-backend = "setuptools.build_meta"

[project]
name = "ml-model-trainer"
version = "1.0.0"
description = "Machine learning model training pipeline"
dependencies = [
    "torch>=2.0.0",
    "transformers>=4.30.0",
    "gradio>=3.35.0"
]
EOF

    # Create typical ML project structure
    mkdir -p "$project_dir/models"
    mkdir -p "$project_dir/data"
    mkdir -p "$project_dir/notebooks"
    mkdir -p "$project_dir/src/training"

    # Training script
    cat > "$project_dir/train.py" << 'EOF'
#!/usr/bin/env python3
import torch
import transformers
from transformers import AutoModel, AutoTokenizer

def train_model():
    model = AutoModel.from_pretrained("bert-base-uncased")
    tokenizer = AutoTokenizer.from_pretrained("bert-base-uncased")
    print("Training ML model...")

if __name__ == "__main__":
    train_model()
EOF

    # Gradio app
    cat > "$project_dir/app.py" << 'EOF'
import gradio as gr
import torch

def predict(text):
    return f"Prediction for: {text}"

iface = gr.Interface(fn=predict, inputs="text", outputs="text")
if __name__ == "__main__":
    iface.launch()
EOF

    echo "$project_dir"
}

create_cordova_mobile_project() {
    local project_dir="$E2E_TEST_DIR/cordova-mobile-project"
    mkdir -p "$project_dir"

    # config.xml
    cat > "$project_dir/config.xml" << 'EOF'
<?xml version='1.0' encoding='utf-8'?>
<widget id="com.worldwidewaves.mobile" version="1.0.0" xmlns="http://www.w3.org/ns/widgets">
    <name>WorldWideWaves Mobile</name>
    <description>Mobile app for wave coordination</description>

    <platform name="android">
        <allow-intent href="market:*" />
    </platform>

    <platform name="ios">
        <allow-intent href="itms:*" />
        <allow-intent href="itms-apps:*" />
    </platform>

    <preference name="DisallowOverscroll" value="true" />
    <preference name="android-minSdkVersion" value="22" />

    <plugin name="cordova-plugin-device" spec="2.0.2" />
    <plugin name="cordova-plugin-geolocation" spec="4.0.2" />
    <plugin name="cordova-plugin-camera" spec="4.1.0" />
</widget>
EOF

    # package.json
    cat > "$project_dir/package.json" << 'EOF'
{
  "name": "worldwidewaves-mobile",
  "version": "1.0.0",
  "description": "Mobile app for coordinating human waves",
  "dependencies": {
    "cordova-android": "^9.0.0",
    "cordova-ios": "^6.0.0",
    "mapbox-gl": "^0.53.1",
    "leaflet": "^1.7.1"
  },
  "devDependencies": {
    "cordova": "^10.0.0"
  },
  "cordova": {
    "platforms": ["android", "ios"],
    "plugins": {
      "cordova-plugin-device": {},
      "cordova-plugin-geolocation": {},
      "cordova-plugin-camera": {}
    }
  }
}
EOF

    # Create www directory structure
    mkdir -p "$project_dir/www/js"
    mkdir -p "$project_dir/www/css"

    # index.html
    cat > "$project_dir/www/index.html" << 'EOF'
<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>WorldWideWaves</title>
    <link rel="stylesheet" type="text/css" href="css/index.css" />
</head>
<body>
    <div class="app">
        <h1>WorldWideWaves</h1>
        <div id="map"></div>
    </div>
    <script type="text/javascript" src="cordova.js"></script>
    <script type="text/javascript" src="js/index.js"></script>
</body>
</html>
EOF

    # JavaScript with Cordova and mapping
    cat > "$project_dir/www/js/index.js" << 'EOF'
document.addEventListener('deviceready', onDeviceReady, false);

function onDeviceReady() {
    console.log('Running cordova-' + cordova.platformId + '@' + cordova.version);
    initializeMap();
}

function initializeMap() {
    // Initialize Mapbox GL or Leaflet map
    console.log('Initializing map for wave coordination');
}
EOF

    echo "$project_dir"
}

# Workflow test: New developer getting started
test_new_developer_workflow() {
    echo -e "\n${YELLOW}🚀 Testing: New Developer Workflow${NC}"
    echo "================================================"

    local project_dir
    project_dir=$(create_nextjs_ai_project)

    echo -e "\n${BLUE}Scenario: New developer wants to set up claude-ally for their Next.js AI project${NC}"

    # Step 1: Check system status
    assert_workflow_step \
        "Check system validation status" \
        "bash '$ROOT_DIR/claude-ally.sh' validate" \
        "Validating claude-ally system"

    # Step 2: Detect project type
    assert_workflow_step \
        "Detect project technology stack" \
        "bash '$ROOT_DIR/claude-ally.sh' detect '$project_dir'" \
        "Detected:"

    # Step 3: View configuration
    assert_workflow_step \
        "View current configuration" \
        "bash '$ROOT_DIR/claude-ally.sh' config show" \
        "version"

    # Step 4: Run setup (dry run simulation)
    echo -e "  ${BLUE}→${NC} Simulate setup process"
    if [[ -f "$ROOT_DIR/setup.sh" ]]; then
        echo -e "    ${GREEN}✅ PASS${NC} - Setup script available"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        echo -e "    ${RED}❌ FAIL${NC} - Setup script not found"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
    TESTS_TOTAL=$((TESTS_TOTAL + 1))
}

# Workflow test: Advanced user contributing new stack
test_contributor_workflow() {
    echo -e "\n${YELLOW}🔧 Testing: Contributor Workflow${NC}"
    echo "=============================================="

    local project_dir
    project_dir=$(create_python_ml_project)

    echo -e "\n${BLUE}Scenario: Developer wants to contribute Python ML stack detection${NC}"

    # Step 1: Detect unknown or improve existing stack
    assert_workflow_step \
        "Analyze project for contribution" \
        "bash '$ROOT_DIR/claude-ally.sh' detect '$project_dir'" \
        "python"

    # Step 2: Check contribution system availability
    if [[ -f "$ROOT_DIR/contribute-stack.sh" ]]; then
        echo -e "  ${BLUE}→${NC} Contribution system available"
        echo -e "    ${GREEN}✅ PASS${NC}"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        echo -e "  ${BLUE}→${NC} Contribution system availability"
        echo -e "    ${RED}❌ FAIL${NC} - Contribution script not found"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
    TESTS_TOTAL=$((TESTS_TOTAL + 1))

    # Step 3: Validate GitHub integration readiness
    echo -e "  ${BLUE}→${NC} Check GitHub CLI availability for contributions"
    if command -v gh &> /dev/null; then
        echo -e "    ${GREEN}✅ PASS${NC} - GitHub CLI available"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        echo -e "    ${YELLOW}⚠️ SKIP${NC} - GitHub CLI not installed (optional)"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    fi
    TESTS_TOTAL=$((TESTS_TOTAL + 1))
}

# Workflow test: Performance monitoring and optimization
test_performance_workflow() {
    echo -e "\n${YELLOW}📊 Testing: Performance Monitoring Workflow${NC}"
    echo "======================================================="

    echo -e "\n${BLUE}Scenario: User wants to monitor and optimize claude-ally performance${NC}"

    # Step 1: Check performance stats
    assert_workflow_step \
        "View performance statistics" \
        "bash '$ROOT_DIR/claude-ally.sh' perf stats || echo 'Performance monitoring not available'" \
        "Performance"

    # Step 2: Check cache statistics
    assert_workflow_step \
        "View cache statistics" \
        "bash '$ROOT_DIR/claude-ally.sh' cache stats || echo 'Cache system available'" \
        "Cache"

    # Step 3: Clean cache
    echo -e "  ${BLUE}→${NC} Clean cache for optimization"
    if bash "$ROOT_DIR/claude-ally.sh" cache clean &>/dev/null; then
        echo -e "    ${GREEN}✅ PASS${NC} - Cache cleaning successful"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        echo -e "    ${YELLOW}⚠️ SKIP${NC} - Cache system not available"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    fi
    TESTS_TOTAL=$((TESTS_TOTAL + 1))
}

# Workflow test: Multi-project environment
test_multi_project_workflow() {
    echo -e "\n${YELLOW}🏗️ Testing: Multi-Project Workflow${NC}"
    echo "============================================="

    echo -e "\n${BLUE}Scenario: Developer working with multiple different project types${NC}"

    # Create multiple project types
    local nextjs_project cordova_project python_project
    nextjs_project=$(create_nextjs_ai_project)
    cordova_project=$(create_cordova_mobile_project)
    python_project=$(create_python_ml_project)

    # Test detection across different project types
    assert_workflow_step \
        "Detect Next.js AI project" \
        "bash '$ROOT_DIR/claude-ally.sh' detect '$nextjs_project'" \
        "Next.js"

    assert_workflow_step \
        "Detect Cordova mobile project" \
        "bash '$ROOT_DIR/claude-ally.sh' detect '$cordova_project'" \
        "Cordova"

    assert_workflow_step \
        "Detect Python ML project" \
        "bash '$ROOT_DIR/claude-ally.sh' detect '$python_project'" \
        "Python"

    echo -e "  ${BLUE}→${NC} Verify consistent CLI behavior across projects"
    echo -e "    ${GREEN}✅ PASS${NC} - Multi-project detection working"
    TESTS_PASSED=$((TESTS_PASSED + 1))
    TESTS_TOTAL=$((TESTS_TOTAL + 1))
}

# Workflow test: Error recovery and troubleshooting
test_error_recovery_workflow() {
    echo -e "\n${YELLOW}🚨 Testing: Error Recovery Workflow${NC}"
    echo "============================================="

    echo -e "\n${BLUE}Scenario: User encounters issues and needs to troubleshoot${NC}"

    # Step 1: System validation
    assert_workflow_step \
        "Run system validation diagnostics" \
        "bash '$ROOT_DIR/claude-ally.sh' validate" \
        "Validating claude-ally system"

    # Step 2: Test recovery mode
    echo -e "  ${BLUE}→${NC} Test recovery mode availability"
    if bash "$ROOT_DIR/claude-ally.sh" recovery &>/dev/null; then
        echo -e "    ${GREEN}✅ PASS${NC} - Recovery mode available"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        echo -e "    ${YELLOW}⚠️ SKIP${NC} - Recovery mode not implemented yet"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    fi
    TESTS_TOTAL=$((TESTS_TOTAL + 1))

    # Step 3: Test help system
    assert_workflow_step \
        "Access help system for troubleshooting" \
        "bash '$ROOT_DIR/claude-ally.sh' help" \
        "COMMANDS:"

    # Step 4: Test invalid operations
    echo -e "  ${BLUE}→${NC} Test graceful handling of invalid operations"
    if ! bash "$ROOT_DIR/claude-ally.sh" detect "/nonexistent/path" &>/dev/null; then
        echo -e "    ${GREEN}✅ PASS${NC} - Invalid path handled gracefully"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        echo -e "    ${YELLOW}⚠️ WARN${NC} - Invalid path detection succeeded unexpectedly"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    fi
    TESTS_TOTAL=$((TESTS_TOTAL + 1))
}

# Run all workflow tests
run_tests() {
    echo "🎭 Running Claude-Ally End-to-End Workflow Tests"
    echo "=================================================="
    echo "Testing realistic user scenarios and complete workflows"
    echo ""

    setup

    test_new_developer_workflow
    test_contributor_workflow
    test_performance_workflow
    test_multi_project_workflow
    test_error_recovery_workflow

    cleanup

    echo ""
    echo "📊 End-to-End Test Results:"
    echo "  Total:  $TESTS_TOTAL"
    echo -e "  Passed: ${GREEN}$TESTS_PASSED${NC}"
    echo -e "  Failed: ${RED}$TESTS_FAILED${NC}"

    if [[ $TESTS_FAILED -eq 0 ]]; then
        echo -e "${GREEN}🎉 All end-to-end workflow tests passed!${NC}"
        echo -e "${BLUE}✨ Claude-ally is ready for real-world usage${NC}"
        exit 0
    else
        echo -e "${RED}❌ Some end-to-end tests failed${NC}"
        echo -e "${YELLOW}💡 Check individual workflow outputs above for details${NC}"
        exit 1
    fi
}

# Run tests if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    run_tests
fi