import os
import subprocess
import time
import shutil
import sys

# --- CONFIG ---
INSTANCE_NAME = "filemind-gpu"
ZONE = "us-central1-a"
GCLOUD = "/root/google-cloud-sdk/bin/gcloud"
INPUT_DIR = "/root/incoming_files"
FILTERED_DIR = "/root/filtered_files"
VALID_EXTENSIONS = [".jpg", ".jpeg", ".png", ".gif", ".txt", ".pdf", ".docx", ".doc", ".heic"]

def run_or_fail(cmd: list, desc: str):
    print(f"▶️ {desc}...")
    result = subprocess.run(cmd)
    if result.returncode != 0:
        print(f"❌ Failed during: {desc}")
        sys.exit(1)

def main():
    if not os.path.exists(INPUT_DIR):
        print(f"❌ Error: Input directory does not exist → {INPUT_DIR}")
        sys.exit(1)

    print("🚀 Starting full backend pipeline...")
    run_or_fail(
        ["python3", "/root/start_pipeline_gc.py"],
        "Running start_pipeline_gc.py"
    )

if __name__ == '__main__':
    main()
