#!/usr/bin/env python
"""
Parse TensorFlow Serving output
"""

import json
import sys
import argparse


def parse_tf_output(output_json):
    """Parse the TensorFlow Serving output"""
    try:
        data = json.loads(output_json)

        if "outputs" not in data:
            return "Error: No 'outputs' field in response"

        outputs = data["outputs"]

        # Different models may have different output formats
        # Try a few common formats

        # Format 1: Direct string output
        if isinstance(outputs, str):
            return outputs

        # Format 2: List of characters
        elif isinstance(outputs, list):
            return "".join(outputs)

        # Format 3: Dictionary with 'prediction' key
        elif isinstance(outputs, dict) and "prediction" in outputs:
            return outputs["prediction"]

        # Format 4: Dictionary with class probabilities
        elif isinstance(outputs, dict):
            # Just return the raw output for inspection
            return json.dumps(outputs, indent=2)

        # Otherwise, just return the raw output
        return json.dumps(outputs, indent=2)

    except json.JSONDecodeError:
        return "Error: Invalid JSON format"
    except Exception as e:
        return f"Error parsing output: {str(e)}"


def main():
    """Parse TensorFlow Serving output from file or stdin"""
    parser = argparse.ArgumentParser(description="Parse TensorFlow Serving output")
    parser.add_argument(
        "--file", "-f", help="JSON response file (if not provided, reads from stdin)"
    )

    args = parser.parse_args()

    if args.file:
        try:
            with open(args.file, "r") as f:
                output_json = f.read()
        except Exception as e:
            print(f"Error reading file: {str(e)}")
            sys.exit(1)
    else:
        # Read from stdin
        output_json = sys.stdin.read()

    result = parse_tf_output(output_json)
    print(result)


if __name__ == "__main__":
    main()
