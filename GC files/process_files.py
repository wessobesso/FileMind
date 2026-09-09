import os
import sys
import json
import requests
from datetime import datetime
from PIL import Image
import base64
import fitz  # PyMuPDF
import shutil

# === Config ===
FILES_DIR = "/root/incoming_files"
OUTPUT_JSON = "/root/filemind_output.json"

# === Helper: Talk to Ollama ===
def ollama_prompt(model: str, prompt: str, images: list = None):
    body = {
        "model": model,
        "prompt": prompt,
        "stream": False
    }
    if images:
        body["images"] = images
    try:
        res = requests.post("http://localhost:11434/api/generate", json=body, timeout=120)
        res.raise_for_status()
        return res.json()["response"].strip()
    except Exception as e:
        return f"[Error generating summary: {e}]"

# === Helper: Encode Image as Base64 ===
def encode_image(image_path):
    with open(image_path, "rb") as f:
        return base64.b64encode(f.read()).decode()

# === Process Files ===
if not os.path.exists(FILES_DIR):
    print(f"❌ Error: FILES_DIR does not exist → {FILES_DIR}")
    sys.exit(1)

print(f"📁 Scanning files in {FILES_DIR}...")
results = []

for fname in os.listdir(FILES_DIR):
    fpath = os.path.join(FILES_DIR, fname)
    if not os.path.isfile(fpath):
        continue

    ext = fname.lower().split(".")[-1]
    entry = {
        "path": fpath,
        "timestamp": datetime.now().isoformat()
    }

    try:
        # === Image Files ===
        if ext in ["jpg", "jpeg", "png", "webp", "bmp"]:
            print(f"🖼️ Image: {fname}")
            img_b64 = encode_image(fpath)
            prompt = "What is this image showing? Be specific and detailed like a human."
            caption = ollama_prompt("llava", prompt, images=[img_b64])
            entry["type"] = "image"
            entry["summary"] = caption

        # === Text Files ===
        elif ext in ["txt", "md", "log", "json", "csv"]:
            print(f"📄 Text: {fname}")
            with open(fpath, "r", encoding="utf-8", errors="ignore") as f:
                content = f.read()
            prompt = f"Summarize the following text like a human would:\n\n{content}"
            summary = ollama_prompt("mistral", prompt)
            entry["type"] = "text"
            entry["summary"] = summary

        # === PDF Files ===
        elif ext == "pdf":
            print(f"📄 PDF: {fname}")
            doc = fitz.open(fpath)
            text = ""
            for page in doc:
                text += page.get_text()
            doc.close()
            prompt = f"Summarize this document as if you read it:\n\n{text}"
            summary = ollama_prompt("mistral", prompt)
            entry["type"] = "pdf"
            entry["summary"] = summary

        else:
            print(f"⏩ Skipping unsupported file: {fname}")
            continue

        results.append(entry)

    except Exception as e:
        print(f"❌ Error processing {fname}: {e}")
        entry["summary"] = f"[Error generating summary: {e}]"
        results.append(entry)

# === Save Results ===
print(f"💾 Saving results to {OUTPUT_JSON}")
with open(OUTPUT_JSON, "w") as f:
    json.dump(results, f, indent=2)

# === Clean Up GC Input Files ===
print(f"🧹 Deleting files in {FILES_DIR} on GC...")
for fname in os.listdir(FILES_DIR):
    fpath = os.path.join(FILES_DIR, fname)
    try:
        if os.path.isfile(fpath) or os.path.islink(fpath):
            os.unlink(fpath)
        elif os.path.isdir(fpath):
            shutil.rmtree(fpath)
    except Exception as e:
        print(f"⚠️ Could not delete {fpath}: {e}")

print("✅ Done.")
