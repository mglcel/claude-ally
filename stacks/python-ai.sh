#!/bin/bash
# Python AI/ML Stack Detection
# Detects Python applications with AI/ML focus (PyTorch, TensorFlow, etc.)

detect_python_ai() {
    local project_dir="$1"
    local confidence=0
    local tech_stack=""
    local project_type=""

    # Check for Python indicators
    if [[ -f "$project_dir/requirements.txt" ]] || [[ -f "$project_dir/pyproject.toml" ]] || [[ -f "$project_dir/setup.py" ]]; then
        confidence=$((confidence + 20))
    fi

    # Check for AI/ML libraries in requirements.txt
    if [[ -f "$project_dir/requirements.txt" ]]; then
        local ai_ml_patterns=("torch" "tensorflow" "transformers" "gradio" "streamlit" "scikit-learn" "sklearn" "numpy" "pandas" "jupyter")
        local framework=""

        for pattern in "${ai_ml_patterns[@]}"; do
            if grep -q -i "$pattern" "$project_dir/requirements.txt"; then
                confidence=$((confidence + 15))
                case "$pattern" in
                    "torch") framework="PyTorch" ;;
                    "tensorflow") framework="TensorFlow" ;;
                    "transformers") framework="Transformers" ;;
                    "gradio"|"streamlit") framework="$framework, UI" ;;
                esac
            fi
        done

        if [[ -n "$framework" ]]; then
            tech_stack="Python/$framework, AI/ML"
            project_type="ai-ml-service"
        fi
    fi

    # Check for AI/ML project structure
    if [[ -d "$project_dir/models" ]] || [[ -d "$project_dir/notebooks" ]] || [[ -f "$project_dir/train.py" ]] || [[ -f "$project_dir/infer.py" ]]; then
        confidence=$((confidence + 20))
    fi

    # Check for specific AI/ML files
    local ml_files=("model.py" "dataset.py" "trainer.py" "inference.py")
    for file in "${ml_files[@]}"; do
        if [[ -f "$project_dir/$file" ]]; then
            confidence=$((confidence + 10))
        fi
    done

    # Minimum confidence threshold
    if [[ $confidence -ge 50 ]] && [[ "$project_type" == "ai-ml-service" ]]; then
        echo "python-ai|$tech_stack|$project_type|$confidence"
        return 0
    fi

    return 1
}

get_python_ai_patterns() {
    cat << 'EOF'
PYTHON AI/ML SERVICE PATTERNS
Python_AI_Patterns (CRITICAL - Model Performance & Data Security):
  CRITICAL_AI_ML:
    - "Model", "training", "inference" → Model performance and accuracy
    - "Dataset", "preprocessing", "feature" → Data quality and bias validation
    - "GPU", "CUDA", "memory" → Resource utilization and optimization
  HIGH_PRIORITY:
    - "Checkpoint", "versioning", "registry" → Model lifecycle management
    - "Privacy", "anonymization", "PII" → Data privacy and security
    - "Hyperparameter", "tuning", "optimization" → Model performance tuning
EOF
}

get_python_ai_assets() {
    echo "trained models, datasets, model checkpoints, configuration files, API keys"
}

get_python_ai_requirements() {
    echo "GPU resource management, model versioning, data privacy compliance, inference optimization"
}

get_python_ai_issues() {
    echo "CUDA memory management, model overfitting, data leakage, inference latency, dependency conflicts"
}