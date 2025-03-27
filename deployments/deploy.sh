#!/bin/bash
# Script to deploy CAPTCHA22 container

set -e

# Default values
CAPTCHA_DIR=""
OUTPUT_DIR="./output"
MODEL_DIR="./model"
MODE="auto"
MODEL_NAME="captcha_model"

# Display usage information
usage() {
    echo "Usage: $0 -c CAPTCHA_DIR [-o OUTPUT_DIR] [-m MODEL_DIR] [-n MODEL_NAME] [-t MODE]"
    echo ""
    echo "  -c CAPTCHA_DIR   Directory containing labeled captchas (required)"
    echo "  -o OUTPUT_DIR    Directory for output (default: ./output)"
    echo "  -m MODEL_DIR     Directory for model storage (default: ./model)"
    echo "  -n MODEL_NAME    Name of the model (default: captcha_model)"
    echo "  -t MODE          Training mode (default: auto)"
    echo "                   Options: auto, process, train, deploy, serve"
    echo ""
    echo "Example: $0 -c ./my_captchas -o ./my_output -m ./my_model -n my_captcha_model"
    exit 1
}

# Parse command line arguments
while getopts "c:o:m:n:t:" opt; do
    case $opt in
        c) CAPTCHA_DIR="$OPTARG" ;;
        o) OUTPUT_DIR="$OPTARG" ;;
        m) MODEL_DIR="$OPTARG" ;;
        n) MODEL_NAME="$OPTARG" ;;
        t) MODE="$OPTARG" ;;
        *) usage ;;
    esac
done

# Check if captcha directory is provided
if [ -z "$CAPTCHA_DIR" ] && [ "$MODE" != "train" ] && [ "$MODE" != "deploy" ] && [ "$MODE" != "serve" ]; then
    echo "Error: Captcha directory is required"
    usage
fi

# Check if captcha directory exists
if [ ! -z "$CAPTCHA_DIR" ] && [ ! -d "$CAPTCHA_DIR" ]; then
    echo "Error: Captcha directory not found: $CAPTCHA_DIR"
    exit 1
fi

# Create output and model directories if they don't exist
mkdir -p "$OUTPUT_DIR" "$MODEL_DIR"

# Export environment variables for docker-compose
export CAPTCHA_INPUT_DIR="$CAPTCHA_DIR"
export CAPTCHA_OUTPUT_DIR="$OUTPUT_DIR"
export MODEL_DIR="$MODEL_DIR"
export MODEL_NAME="$MODEL_NAME"
export TRAINING_MODE="$MODE"

# Navigate to the deployments directory
cd "$(dirname "$0")"

# Run docker-compose
echo "Starting CAPTCHA22 container..."
echo "- Captcha directory: $CAPTCHA_DIR"
echo "- Output directory: $OUTPUT_DIR"
echo "- Model directory: $MODEL_DIR"
echo "- Model name: $MODEL_NAME"
echo "- Mode: $MODE"

docker-compose up --build

echo "Container exited. Check the output directory for results."
