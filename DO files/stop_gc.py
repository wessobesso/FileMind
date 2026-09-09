import subprocess

INSTANCE_NAME = "filemind-gpu"
ZONE = "us-central1-a"

print("Stopping GC instance...")
subprocess.run(["gcloud", "compute", "instances", "stop", INSTANCE_NAME, "--zone", ZONE])
print("GC instance has been stopped.")
