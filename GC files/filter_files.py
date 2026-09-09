import os
import shutil

SOURCE_DIR = "/root/received_files"
DEST_DIR = "/root/filtered_files"
VALID_EXTENSIONS = [".jpg", ".jpeg", ".png", ".gif", ".bmp", ".txt", ".md", ".pdf"]

os.makedirs(DEST_DIR, exist_ok=True)

for root_dir, _, files in os.walk(SOURCE_DIR):
    for filename in files:
        ext = os.path.splitext(filename)[1].lower()
        if ext.lower() in VALID_EXTENSIONS:
            src_path = os.path.join(root_dir, filename)
            dst_path = os.path.join(DEST_DIR, filename)
            shutil.copy2(src_path, dst_path)
