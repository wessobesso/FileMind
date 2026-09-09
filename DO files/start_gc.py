import subprocess

INSTANCE_NAME = "filemind-gpu"
ZONE = "us-central1-a"

print(f"Starting GC instance '{INSTANCE_NAME}' in zone '{ZONE}'...")
result = subprocess.run(["gcloud", "compute", "instances", "start", INSTANCE_NAME, "--zone", ZONE])

if result.returncode == 0:
    print("Instance started successfully.")
else:
    print("Failed to start the instance.")
