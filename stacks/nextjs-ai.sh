#!/bin/bash
# Next.js + AI/LLM Stack Detection
# Detects Next.js applications with AI/LLM integration

detect_nextjs_ai() {
    local project_dir="$1"
    local confidence=0
    local tech_stack=""
    local project_type=""

    # Check for Next.js indicators
    if [[ -f "$project_dir/next.config.js" ]] || [[ -f "$project_dir/next.config.mjs" ]] || [[ -f "$project_dir/next.config.ts" ]]; then
        confidence=$((confidence + 30))
        tech_stack="Next.js"
        project_type="web-app"
    fi

    # Check for React/Next.js in package.json
    if [[ -f "$project_dir/package.json" ]]; then
        if grep -q -i "\"next\"" "$project_dir/package.json"; then
            confidence=$((confidence + 25))
            if [[ -z "$tech_stack" ]]; then
                tech_stack="Next.js"
            fi
        fi

        # Check for AI/LLM libraries
        local ai_patterns=("@ai-sdk" "openai" "anthropic" "llama" "ollama" "vllm" "huggingface" "transformers.js")
        local ai_found=0

        for pattern in "${ai_patterns[@]}"; do
            if grep -q -i "$pattern" "$project_dir/package.json"; then
                ai_found=1
                confidence=$((confidence + 20))
                break
            fi
        done

        if [[ $ai_found -eq 1 ]]; then
            tech_stack="$tech_stack, AI/LLM"
            project_type="nextjs-ai-app"
        fi

        # Additional Next.js ecosystem detection
        if grep -q -i "tailwindcss" "$project_dir/package.json"; then
            tech_stack="$tech_stack, Tailwind"
            confidence=$((confidence + 10))
        fi

        if grep -q -i "typescript" "$project_dir/package.json" || [[ -f "$project_dir/tsconfig.json" ]]; then
            tech_stack="TypeScript/$tech_stack"
            confidence=$((confidence + 10))
        fi
    fi

    # Check for Next.js directory structure
    if [[ -d "$project_dir/src/app" ]] || [[ -d "$project_dir/pages" ]] || [[ -d "$project_dir/app" ]]; then
        confidence=$((confidence + 15))
    fi

    # Minimum confidence threshold
    if [[ $confidence -ge 50 ]]; then
        echo "nextjs-ai|$tech_stack|$project_type|$confidence"
        return 0
    fi

    return 1
}

get_nextjs_ai_patterns() {
    cat << 'EOF'
NEXTJS AI APPLICATION PATTERNS
NextJS_AI_Patterns (CRITICAL - AI Integration & Web Performance):
  CRITICAL_NEXTJS_AI:
    - "API route", "/api/", "edge runtime" → API security and rate limiting
    - "streaming", "completion", "chat" → AI response handling and UX
    - "token", "tokenizer", "context window" → LLM resource management
  HIGH_PRIORITY:
    - "middleware", "auth", "session" → Authentication for AI features
    - "environment", "API key", "model" → Secure AI service configuration
    - "Suspense", "loading", "error boundary" → AI loading states and error handling
EOF
}

get_nextjs_ai_assets() {
    echo "AI API keys, user conversations, model configurations, authentication tokens"
}

get_nextjs_ai_requirements() {
    echo "Rate limiting for AI APIs, secure API key management, streaming response handling"
}

get_nextjs_ai_issues() {
    echo "API rate limits, model context windows, streaming response handling, client-side state management"
}