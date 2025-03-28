#!/usr/bin/env python
"""
Test script for CAPTCHA22 model
This script tests a deployed CAPTCHA22 model by sending a CAPTCHA image for solution
"""

import argparse
import os
import sys
import requests
import base64
import json
import time
from captcha22 import Cracker


def check_server_status(url, port, model):
    """Check if the TensorFlow Serving is running"""
    try:
        response = requests.get(f"{url}:{port}/v1/models/{model}")
        if response.status_code == 200:
            return True
        return False
    except requests.exceptions.RequestException:
        return False


def solve_with_direct_api(image_path, url, port, model):
    """Solve CAPTCHA using direct TensorFlow Serving API"""
    try:
        # Read the image file
        with open(image_path, "rb") as image_file:
            encoded_string = base64.b64encode(image_file.read()).decode("utf-8")

        # Prepare the request
        payload = {
            "signature_name": "serving_default",
            "inputs": {"input": {"b64": encoded_string}},
        }

        # Send the request
        response = requests.post(
            f"{url}:{port}/v1/models/{model}:predict",
            headers={"content-type": "application/json"},
            data=json.dumps(payload),
        )

        # Parse the response
        if response.status_code == 200:
            result = response.json()
            if "outputs" in result:
                # The actual structure depends on your model's output format
                # Typically it's something like:
                try:
                    prediction = result["outputs"]
                    # This might need adjustment based on the actual response format
                    if isinstance(prediction, list):
                        return "".join(prediction)
                    elif isinstance(prediction, dict):
                        return prediction.get("prediction", "Unknown format")
                    return str(prediction)
                except (KeyError, TypeError):
                    return f"Unable to parse response: {result}"
            else:
                return f"No outputs in response: {result}"
        else:
            return f"Error: {response.status_code} - {response.text}"
    except Exception as e:
        return f"Error using direct API: {str(e)}"


def main():
    """Main function to test the CAPTCHA model"""
    parser = argparse.ArgumentParser(description="Test a deployed CAPTCHA22 model")
    parser.add_argument(
        "--image", "-i", required=True, help="Path to the CAPTCHA image"
    )
    parser.add_argument("--url", default="http://localhost", help="Model server URL")
    parser.add_argument("--port", default="9001", help="Model server port")
    parser.add_argument("--model", default="captcha_model", help="Model name")
    parser.add_argument(
        "--method",
        default="auto",
        choices=["auto", "cracker", "direct"],
        help="Method to use for solving (auto, cracker, direct)",
    )
    parser.add_argument(
        "--verbose", "-v", action="store_true", help="Show verbose output"
    )

    args = parser.parse_args()

    if not os.path.exists(args.image):
        print(f"Error: Image file not found: {args.image}")
        sys.exit(1)

    # Check if server is running
    print(f"Checking if model server is running at {args.url}:{args.port}...")

    server_running = check_server_status(args.url, args.port, args.model)
    if not server_running:
        print(f"Error: Cannot connect to model server at {args.url}:{args.port}")
        print("Make sure the server is running and accessible.")
        sys.exit(1)

    print(f"Server is running and accessible!")
    print(f"Solving CAPTCHA: {args.image}")

    # Try to solve the CAPTCHA
    start_time = time.time()

    if args.method == "direct" or (args.method == "auto" and args.port == "9001"):
        try:
            # Try direct TensorFlow Serving API first if port is 9001
            answer = solve_with_direct_api(args.image, args.url, args.port, args.model)
            method_used = "Direct TensorFlow Serving API"
        except Exception as e:
            if args.verbose:
                print(f"Direct API method failed: {e}")
            if args.method == "direct":
                print(f"Error using direct API: {e}")
                sys.exit(1)
            # Fall back to Cracker method
            answer = None

    if args.method == "cracker" or (args.method == "auto" and not answer):
        try:
            # Create cracker instance
            solver = Cracker(
                server_url=args.url,
                server_port=args.port,
                use_local=True,
                captcha_id=args.model,
            )

            # Solve the CAPTCHA
            answer = solver.solve_captcha_file(args.image)
            method_used = "CAPTCHA22 Cracker"
        except Exception as e:
            print(f"Error using CAPTCHA22 Cracker: {e}")
            sys.exit(1)

    elapsed_time = time.time() - start_time

    # Check if we got a valid answer
    if answer:
        print(f"CAPTCHA solution: {answer}")
        print(f"Method used: {method_used}")
        print(f"Time taken: {elapsed_time:.2f} seconds")
    else:
        print("Failed to solve CAPTCHA")
        sys.exit(1)


if __name__ == "__main__":
    main()

