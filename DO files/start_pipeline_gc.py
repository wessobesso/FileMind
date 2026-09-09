import os
import subprocess
import time
import shutil
import sys
import pathlib

# --- CONFIG ---
INSTANCE_NAME = "filemind-gpu"
ZONE = "us-central1-a"
GCLOUD = "/root/google-cloud-sdk/bin/gcloud"
LOCAL_SOURCE = "/root/incoming_files"
FILTERED_DIR = "/root/filtered_files"
GC_TARGET_DIR = "/root/incoming_files"
VALID_EXTENSIONS = [".jpg", ".jpeg", ".png", ".gif", ".txt", ".pdf", ".docx", ".doc", ".heic"]

def run_or_fail(cmd: list, desc: str):
    print(f"▶️ {desc}...")
    result = subprocess.run(cmd)
    if result.returncode != 0:
        print(f"❌ Failed during: {desc}")
        sys.exit(1)

def clear_directory(dir_path: str):
    print(f"🧹 Clearing directory: {dir_path}")
    try:
        for entry in os.scandir(dir_path):
            path = pathlib.Path(entry.path)
            if path.is_file() or path.is_symlink():
                path.unlink()
            elif path.is_dir():
                shutil.rmtree(path)
        print(f"✅ Directory cleared: {dir_path}")
    except Exception as e:
        print(f"⚠️ Failed to clear {dir_path}: {e}")

def main():
    if not os.path.exists(LOCAL_SOURCE):
        print(f"❌ Error: Source directory does not exist → {LOCAL_SOURCE}")
        sys.exit(1)

    # --- 1. Start GC instance ---
    print("🟡 Starting GC instance...")
    run_or_fail(
        [GCLOUD, "compute", "instances", "start", INSTANCE_NAME, "--zone", ZONE],
        "Starting GC instance"
    )

    print("⏳ Waiting 30s for GC to boot...")
    time.sleep(30)

    # --- 2. Filter files ---
    print("🧹 Filtering valid files from local source...")
    os.makedirs(FILTERED_DIR, exist_ok=True)

    filtered_count = 0
    for filename in os.listdir(LOCAL_SOURCE):
        ext = os.path.splitext(filename)[1].lower()
        if ext in VALID_EXTENSIONS:
            src_path = os.path.join(LOCAL_SOURCE, filename)
            dst_path = os.path.join(FILTERED_DIR, filename)
            try:
                shutil.copy2(src_path, dst_path)
                filtered_count += 1
            except Exception as e:
                print(f"⚠️ Failed to copy {src_path}: {e}")

    print(f"✅ {filtered_count} valid files copied to: {FILTERED_DIR}")

    # --- 2.5 Clear local incoming_files after filtering ---
    clear_directory(LOCAL_SOURCE)

    # --- 3. Create target folder on GC ---
    print(f"📦 Creating remote directory on GC: {GC_TARGET_DIR}")
    run_or_fail(
        [GCLOUD, "compute", "ssh", INSTANCE_NAME, "--zone", ZONE,
         "--command", f"mkdir -p {GC_TARGET_DIR}"],
        "Creating target folder on GC"
    )

    # --- 3.5 Clear remote GC target directory ---
    print(f"🧹 Clearing remote directory {GC_TARGET_DIR} on GC...")
    run_or_fail(
        [GCLOUD, "compute", "ssh", INSTANCE_NAME, "--zone", ZONE,
         "--command", f"rm -rf {GC_TARGET_DIR}/*"],
        f"Clearing {GC_TARGET_DIR} on GC"
    )

    # --- 4. Upload files to GC ---
    print("🚀 Sending files to GC...")
    run_or_fail(
        [GCLOUD, "compute", "scp", "--recurse", f"{FILTERED_DIR}/.",
         f"root@{INSTANCE_NAME}:{GC_TARGET_DIR}", "--zone", ZONE],
        "Uploading files to GC"
    )
    print("✅ Files sent to GC.")

    # --- 5. Clean up filtered files ---
    try:
        shutil.rmtree(FILTERED_DIR)
        print(f"🧹 Deleted temporary filtered files at: {FILTERED_DIR}")
    except Exception as e:
        print(f"⚠️ Failed to delete filtered files: {e}")

    # --- 6. Run processing script with virtualenv ---
    print("🧠 Running process_files.py on GC...")
    run_or_fail(
        [GCLOUD, "compute", "ssh", INSTANCE_NAME, "--zone", ZONE,
         "--command", "source /root/filemind-env/bin/activate && python3 /root/process_files.py"],
        "Running process_files.py on GC"
    )

    # --- 7. Retrieve JSON and shutdown GC ---
    print("📥 Retrieving output and shutting down GC...")
    run_or_fail(
        ["bash", "/root/retrieve_and_shutdown.sh"],
        "Retrieving filemind_output.json and shutting down GC"
    )

if __name__ == "__main__":
    main()
