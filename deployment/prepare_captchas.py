#!/usr/bin/env python

import os
import zipfile
import shutil
import argparse
from datetime import datetime


def prepare_captcha_data(input_dir, captcha_name, captcha_version=None):
    """
    Prepare pre-labeled CAPTCHAs into the format expected by Captcha22.

    The input directory should contain files named in the format xxxxx.png,
    where xxxxx is the solution to the CAPTCHA.
    """
    if not captcha_version:
        captcha_version = datetime.now().strftime("%Y%m%d%H%M%S")

    # Create temporary directory for organizing CAPTCHAs
    temp_dir = os.path.join("/tmp", f"{captcha_name}_{captcha_version}")
    if os.path.exists(temp_dir):
        shutil.rmtree(temp_dir)
    os.makedirs(temp_dir)

    print(f"Processing CAPTCHAs from {input_dir}...")

    # Count of processed files
    count = 0

    # Process each file in the input directory
    for filename in os.listdir(input_dir):
        if filename.lower().endswith((".png", ".jpg", ".jpeg")):
            # Extract the label from the filename (assuming format is xxxxx.png)
            label = os.path.splitext(filename)[0]

            # Create directory for this label if it doesn't exist
            label_dir = os.path.join(temp_dir, label)
            os.makedirs(label_dir, exist_ok=True)

            # Copy the file to the label directory
            src_path = os.path.join(input_dir, filename)
            dst_path = os.path.join(label_dir, filename)
            shutil.copy2(src_path, dst_path)
            count += 1

    print(
        f"Processed {count} CAPTCHA images with {len(os.listdir(temp_dir))} unique labels."
    )

    # Create ZIP file for Captcha22
    zip_filename = f"{captcha_name}_{captcha_version}.zip"
    zip_path = os.path.join("/app/Unsorted", zip_filename)

    print(f"Creating ZIP file: {zip_path}")
    with zipfile.ZipFile(zip_path, "w") as zipf:
        for root, dirs, files in os.walk(temp_dir):
            for file in files:
                file_path = os.path.join(root, file)
                arcname = os.path.relpath(file_path, temp_dir)
                zipf.write(file_path, arcname)

    print("ZIP file created. Cleaning up temporary files...")
    shutil.rmtree(temp_dir)

    print(f"Preparation complete. ZIP file ready for Captcha22: {zip_path}")
    return zip_path


if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        description="Prepare pre-labeled CAPTCHAs for Captcha22"
    )
    parser.add_argument(
        "--input", required=True, help="Directory containing pre-labeled CAPTCHAs"
    )
    parser.add_argument(
        "--name", default="my_captcha", help="Name for the CAPTCHA model"
    )
    parser.add_argument("--version", help="Version string (default: timestamp)")

    args = parser.parse_args()
    prepare_captcha_data(args.input, args.name, args.version)
