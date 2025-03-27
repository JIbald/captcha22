#!/usr/bin/env python
"""
Test script for CAPTCHA22 model
This script tests a deployed CAPTCHA22 model by sending a CAPTCHA image for solution
"""

import argparse
import os
import sys
from captcha22 import Cracker


def main():
    """Main function to test the CAPTCHA model"""
    parser = argparse.ArgumentParser(description="Test a deployed CAPTCHA22 model")
    parser.add_argument(
        "--image", "-i", required=True, help="Path to the CAPTCHA image"
    )
    parser.add_argument("--url", default="http://localhost", help="Model server URL")
    parser.add_argument("--port", default="9001", help="Model server port")
    parser.add_argument("--model", default="captcha_model", help="Model name")

    args = parser.parse_args()

    if not os.path.exists(args.image):
        print(f"Error: Image file not found: {args.image}")
        sys.exit(1)

    # Create a cracker instance
    solver = Cracker(
        server_url=args.url,
        server_port=args.port,
        use_local=True,
        captcha_id=args.model,
    )

    try:
        # Solve the CAPTCHA
        print(f"Solving CAPTCHA: {args.image}")
        answer = solver.solve_captcha_file(args.image)

        # Check if we got a valid answer
        if answer:
            print(f"CAPTCHA solution: {answer}")
        else:
            print("Failed to solve CAPTCHA")
    except Exception as e:
        print(f"Error: {e}")
        sys.exit(1)


if __name__ == "__main__":
    main()
