# CAPTCHA22 Docker Deployment

This directory contains Docker deployment files for CAPTCHA22, a toolset for building and training CAPTCHA cracking models using neural networks.

## Prerequisites

- Docker
- Docker Compose
- A folder of labeled CAPTCHA images (format: `xxxxx.png` where `xxxxx` is the solution)

## Quick Start

1. Place your labeled CAPTCHAs in a directory
2. Run the container using docker-compose:

```bash
CAPTCHA_INPUT_DIR=/path/to/your/captchas docker-compose up
```

## Directory Structure

- `/data/input`: Mount your directory containing labeled CAPTCHAs here
- `/data/output`: Output directory for results
- `/data/model`: Directory where the trained model will be saved

## Environment Variables

- `MODEL_NAME`: Name of your CAPTCHA model (default: `captcha_model`)
- `TRAINING_MODE`: Mode to run the container in (default: `auto`)
  - `auto`: Process captchas, train model, and deploy it
  - `process`: Only process the captchas
  - `train`: Only train the model (requires processed captchas)
  - `deploy`: Only deploy the model (requires trained model)
  - `serve`: Only serve an existing model

## Usage Examples

### Full Workflow (Process, Train, Deploy)

```bash
CAPTCHA_INPUT_DIR=/path/to/your/captchas docker-compose up
```

### Only Process Captchas

```bash
CAPTCHA_INPUT_DIR=/path/to/your/captchas TRAINING_MODE=process docker-compose up
```

### Only Train Model

```bash
TRAINING_MODE=train docker-compose up
```

### Deploy and Serve Model

```bash
MODEL_DIR=/path/to/your/model TRAINING_MODE=serve docker-compose up
```

## Using the Trained Model

Once the model is deployed, it will be accessible via:

- REST API: `http://localhost:9001/v1/models/${MODEL_NAME}:predict`

Example curl request:

```bash
curl -X POST \
    http://localhost:9001/v1/models/captcha_model:predict \
    -H 'content-type: application/json' \
    -d '{
            "signature_name": "serving_default",
            "inputs": 
            {
                "input": { "b64": "BASE64_ENCODED_IMAGE" }
            }
        }'
```

## Python Example

```python
from captcha22 import Cracker

solver = Cracker(
    server_url="http://localhost",
    server_port="9001",
    captcha_id="captcha_model"
)

# Solve a captcha
answer = solver.solve_captcha_file("/path/to/captcha.png")
print(f"CAPTCHA solution: {answer}")
```

## Notes

- It's recommended to have at least 200 labeled CAPTCHAs for good results
- Training time will vary based on the complexity of the CAPTCHAs and your hardware
- GPU support can be enabled by modifying the Dockerfile to use a CUDA-enabled base image
