#!/bin/bash
set -e

# Print banner
echo "====================================="
echo "CAPTCHA22 - CAPTCHA Training Container"
echo "====================================="

# Check if captchas directory is empty
if [ -z "$(ls -A /app/captchas 2>/dev/null)" ]; then
    echo "Error: No CAPTCHA files found in /app/captchas"
    echo "Please mount a directory with pre-labeled CAPTCHAs to /app/captchas"
    exit 1
fi

# Default values
CAPTCHA_NAME=${CAPTCHA_NAME:-"my_captcha"}
CAPTCHA_VERSION=${CAPTCHA_VERSION:-$(date +%Y%m%d%H%M%S)}
MODEL_PORT=${MODEL_PORT:-9000}
REST_API_PORT=${REST_API_PORT:-9001}

echo "Preparing CAPTCHA data..."
python /app/prepare_captchas.py --input /app/captchas --name "$CAPTCHA_NAME" --version "$CAPTCHA_VERSION"

echo "Starting CAPTCHA22 Server Engine in the background..."
captcha22 server engine &
ENGINE_PID=$!

# Wait for engine to start
sleep 5

echo "Waiting for model training to complete..."
# Monitor for model completion by checking for the finished model
while true; do
    # Look for the trained model directory
    if ls -d /app/Models/*/*/export/final 2>/dev/null; then
        echo "Model training completed!"
        break
    fi
    echo "Training in progress... (waiting 30 seconds)"
    sleep 30
done

# Get the path to the latest model
MODEL_PATH=$(ls -d /app/Models/*/*/export/final | tail -1)
echo "Using model at: $MODEL_PATH"

# Start tensorflow model server
echo "Starting TensorFlow model server on port $MODEL_PORT (REST API on port $REST_API_PORT)..."
tensorflow_model_server --port=$MODEL_PORT --rest_api_port=$REST_API_PORT --model_name=$CAPTCHA_NAME --model_base_path=$MODEL_PATH &
SERVER_PID=$!

echo "Model server is running. You can now use the model to crack CAPTCHAs."
echo "Example curl request to test your model:"
echo "curl -X POST \\"
echo "    http://localhost:$REST_API_PORT/v1/models/$CAPTCHA_NAME:predict \\"
echo "    -H 'content-type: application/json' \\"
echo "    -d '{\"signature_name\": \"serving_default\", \"inputs\": {\"input\": { \"b64\": \"<base64-image-data>\" }}}'"

echo "Press Ctrl+C to stop the server"
# Keep the container running
wait $SERVER_PID
