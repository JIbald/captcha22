#!/usr/bin/env python
"""
Generate a test request for the TensorFlow Serving model
"""

import argparse
import base64
import json
import os
import sys


def main():
    """Generate a test request for TensorFlow Serving"""
    parser = argparse.ArgumentParser(description="Generate test request for TF Serving")
    parser.add_argument("--image", "-i", required=True, help="Path to CAPTCHA image")
    parser.add_argument("--model", "-m", default="captcha_model", help="Model name")
    parser.add_argument(
        "--output", "-o", default="test_request.json", help="Output file"
    )

    args = parser.parse_args()

    if not os.path.exists(args.image):
        print(f"Error: Image not found: {args.image}")
        sys.exit(1)

    # Read the image and encode it as base64
    with open(args.image, "rb") as f:
        image_data = f.read()
        base64_data = base64.b64encode(image_data).decode("utf-8")

    # Create the request JSON
    request = {
        "signature_name": "serving_default",
        "inputs": {"input": {"b64": base64_data}},
    }

    # Save to file
    with open(args.output, "w") as f:
        json.dump(request, f, indent=2)

    # Generate the curl command
    curl_cmd = (
        f"curl -X POST http://localhost:9001/v1/models/{args.model}:predict \\\n"
        f"  -H 'content-type: application/json' \\\n"
        f"  -d @{args.output}"
    )

    print(f"Request JSON saved to: {args.output}")
    print("\nYou can test the model with this command:")
    print(curl_cmd)


if __name__ == "__main__":
    main()
