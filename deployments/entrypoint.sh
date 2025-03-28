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
    
    # Create the directories structure expected by CAPTCHA22
    mkdir -p "$TEMP_DIR/labelled"
    
    # Process each captcha file
    for file in "$INPUT_DIR"/*.png; do
        if [ -f "$file" ]; then
            # Extract the label from filename (remove extension)
            filename=$(basename "$file")
            label="${filename%.*}"
            
            # Copy the file to the labeled directory
            cp "$file" "$TEMP_DIR/labelled/$label.png"
            echo "Processed: $label"
        fi
    done
    
    # Ensure directory exists
    mkdir -p "${UNSORTED_DIR}"
    
    # Create the ZIP file for training
    echo "Creating training ZIP file..."
    cd "$TEMP_DIR"
    zip -r "${UNSORTED_DIR}/${MODEL_NAME}_1.0.zip" labelled
    cd - > /dev/null
    
    echo "Prepared ZIP file for training: ${UNSORTED_DIR}/${MODEL_NAME}_1.0.zip"
    echo "ZIP contains $(unzip -l "${UNSORTED_DIR}/${MODEL_NAME}_1.0.zip" | grep -c ".png") images"
    
    # Clean up
    rm -rf "$TEMP_DIR"
}

# Function to start the server for training
start_training() {
    echo "Starting CAPTCHA22 server engine for training"
    
    # Ensure models directory exists
    mkdir -p /app/models
    
    # Create a log file for the server
    LOG_FILE="/app/captcha22_training.log"
    
    # Check if the ZIP file exists
    if [ ! -f "${UNSORTED_DIR}/${MODEL_NAME}_1.0.zip" ]; then
        echo "Error: Training data ZIP file not found at ${UNSORTED_DIR}/${MODEL_NAME}_1.0.zip"
        echo "Did you run the 'process' step first?"
        exit 1
    fi
    
    # Start the server with output to log file
    echo "Starting training server, logging to $LOG_FILE"
    captcha22 server engine > "$LOG_FILE" 2>&1 &
    SERVER_PID=$!
    
    echo "Server started with PID: $SERVER_PID"
    
    # Monitor the log file for training progress
    echo "Monitoring training progress..."
    ( tail -f "$LOG_FILE" & ) | grep -q "Training complete" || true
    
    # Check if server is still running
    if kill -0 $SERVER_PID 2>/dev/null; then
        echo "Training is still in progress. This may take a while depending on your dataset size and hardware."
        echo "You can check progress in $LOG_FILE"
        echo "Waiting for training to complete..."
        wait $SERVER_PID || true
    fi
    
    echo "Training process completed"
    
    # Check for model files as verification
    EXPORTED_COUNT=$(find /app/models -type d -name "export" | wc -l)
    if [ "$EXPORTED_COUNT" -eq 0 ]; then
        echo "Warning: No exported model found after training"
        echo "Check $LOG_FILE for any errors"
    else
        echo "Model trained successfully"
    fi
}

# Function to deploy the model
deploy_model() {
    echo "Deploying trained model"
    
    # Find the latest exported model
    EXPORTED_MODEL=$(find /app/models -name "export" -type d | sort | tail -n 1)
    
    if [ -z "$EXPORTED_MODEL" ]; then
        echo "Error: No exported model found"
        echo "Training may have failed or not completed properly."
        exit 1
    fi
    
    echo "Found model at: $EXPORTED_MODEL"
    
    # Create the model directory
    mkdir -p "$MODEL_DIR/1"
    
    # Copy the model to the output directory with correct structure for TF Serving
    cp -r "$EXPORTED_MODEL"/* "$MODEL_DIR/1/"
    
    echo "Model copied to: $MODEL_DIR/1/"
    
    # Verify model files exist
    if [ ! -f "$MODEL_DIR/1/saved_model.pb" ]; then
        echo "Error: Model files not copied correctly"
        echo "Expected to find saved_model.pb in $MODEL_DIR/1/"
        exit 1
    fi
    
    # Save a version file for tracking
    echo "1" > "$MODEL_DIR/version.txt"
    
    # Start TensorFlow Serving with the trained model
    echo "Starting TensorFlow Serving..."
    tensorflow_model_server \
        --port=9000 \
        --rest_api_port=9001 \
        --model_name="$MODEL_NAME" \
        --model_base_path="$MODEL_DIR" > /app/tf_serving.log 2>&1 &
    
    TF_SERVER_PID=$!
    
    # Wait for serving to start
    echo "Waiting for TensorFlow Serving to start..."
    sleep 5
    
    # Check if server started successfully
    if ! kill -0 $TF_SERVER_PID 2>/dev/null; then
        echo "Error: TensorFlow Serving failed to start"
        cat /app/tf_serving.log
        exit 1
    fi
    
    echo "Model deployed and serving at:"
    echo "  - gRPC: localhost:9000"
    echo "  - REST: localhost:9001"
    echo ""
    echo "You can test the model with:"
    echo "curl -X POST http://localhost:9001/v1/models/$MODEL_NAME:predict \\"
    echo "    -H 'content-type: application/json' \\"
    echo "    -d '{\"signature_name\": \"serving_default\", \"inputs\": {\"input\": {\"b64\": \"BASE64_ENCODED_IMAGE\"}}}'"
    echo ""
    echo "Or use the test_captcha_model.py script provided"
    
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
