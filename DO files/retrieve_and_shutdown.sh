#!/bin/bash

REMOTE_JSON_PATH="/root/filemind_output.json"
LOCAL_JSON_PATH="/root/filemind_output.json"

echo "🧹 Deleting old local JSON file if it exists..."
rm -f "$LOCAL_JSON_PATH"

echo "📥 Copying JSON file from GC to DO..."
/root/google-cloud-sdk/bin/gcloud compute scp "filemind-gpu:$REMOTE_JSON_PATH" "$LOCAL_JSON_PATH" --zone=us-central1-a

if [ -f "$LOCAL_JSON_PATH" ]; then
    echo "✅ filemind_output.json received. Proceeding to shutdown GC."
    /root/google-cloud-sdk/bin/gcloud compute instances stop filemind-gpu --zone=us-central1-a
else
    echo "⚠️ filemind_output.json not found at $REMOTE_JSON_PATH. Skipping shutdown."
fi
