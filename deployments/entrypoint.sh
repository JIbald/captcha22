#!/bin/bash
set -e

# Define directories
INPUT_DIR=${INPUT_DIR:-/data/input}
OUTPUT_DIR=${OUTPUT_DIR:-/data/output}
MODEL_DIR=${MODEL_DIR:-/data/model}
UNSORTED_DIR="/app/Unsorted"
TRAINING_MODE=${TRAINING_MODE:-auto}
MODEL_NAME=${MODEL_NAME:-captcha_model}

# Create necessary directories
mkdir -p "$UNSORTED_DIR" "$OUTPUT_DIR" "$MODEL_DIR"

echo "=== CAPTCHA22 Container ==="
echo "Input directory: $INPUT_DIR"
echo "Output directory: $OUTPUT_DIR"
echo "Model directory: $MODEL_DIR"
echo "Training mode: $TRAINING_MODE"
echo "Model name: $MODEL_NAME"

# Function to process pre-labeled captchas
process_captchas() {
    echo "Processing pre-labeled captchas from $INPUT_DIR"
    
    # Create a temporary directory for processing
    TEMP_DIR=$(mktemp -d)
    
    # Count total captchas
    TOTAL=$(find "$INPUT_DIR" -name "*.png" | wc -l)
    echo "Found $TOTAL captcha images"
    
    if [ "$TOTAL" -lt 200 ]; then
        echo "Warning: It's recommended to have at least 200 labeled captchas for good results"
    fi


    mkdir -p "$TEMP_DIR/labelled"

    # Process each captcha file
    for file in "$INPUT_DIR"/*.png; do
        if [ -f "$file" ]; then
            # Extract the label from filename (remove extension)
            filename=$(basename "$file")
            label="${filename%.*}"

            # Copy the file to the labeled directory
            cp "$file" "$TEMP_DIR/labelled/$label.png"
        fi
    done

    # Create the ZIP file for training
    cd "$TEMP_DIR"
    zip -r "${UNSORTED_DIR}/${MODEL_NAME}_1.0.zip" labelled
    cd -

    echo "Prepared ZIP file for training: ${UNSORTED_DIR}/${MODEL_NAME}_1.0.zip"

    # Clean up
    rm -rf "$TEMP_DIR"
}

# Function to start the server for training
start_training() {
    echo "Starting CAPTCHA22 server engine for training"

    # Start the server in the background
    captcha22 server engine &
    SERVER_PID=$!

    echo "Server started with PID: $SERVER_PID"

    # Wait for training to complete
    # This is a simple implementation - in a real scenario,
    # you might want to monitor logs or use the API to check status
    echo "Waiting for training to complete (this may take a while)..."
    wait $SERVER_PID || true

    echo "Training completed"
}

# Function to deploy the model
deploy_model() {
    echo "Deploying trained model"

    # Find the latest exported model
    EXPORTED_MODEL=$(find /app/models -name "export" -type d | sort | tail -n 1)

    if [ -z "$EXPORTED_MODEL" ]; then
        echo "Error: No exported model found"
        exit 1
    fi

    echo "Found model at: $EXPORTED_MODEL"

    # Copy the model to the output directory
    cp -r "$EXPORTED_MODEL" "$MODEL_DIR/"

    echo "Model copied to: $MODEL_DIR"

    # Start TensorFlow Serving with the trained model
    echo "Starting TensorFlow Serving..."
    tensorflow_model_server \
        --port=9000 \
        --rest_api_port=9001 \
        --model_name="$MODEL_NAME" \
        --model_base_path="$MODEL_DIR" &

    # Wait for serving to start
    sleep 5

    echo "Model deployed and serving at:"
    echo "  - gRPC: localhost:9000"
    echo "  - REST: localhost:9001"

    # Keep the container running
    tail -f /dev/null
}

# Main workflow
case "$1" in
    "process")
        process_captchas
        ;;
    "train")
        start_training
        ;;
    "deploy")
        deploy_model
        ;;
    "serve")
        # Just start the model server
        tensorflow_model_server \
            --port=9000 \
            --rest_api_port=9001 \
            --model_name="$MODEL_NAME" \
            --model_base_path="$MODEL_DIR" &

        # Keep the container running
        tail -f /dev/null
        ;;
    "auto" | "")
        # Run the full workflow
        process_captchas
        start_training
        deploy_model
        ;;
    *)
        echo "Unknown command: $1"
        echo "Available commands: process, train, deploy, serve, auto"
        exit 1
        ;;
esac
