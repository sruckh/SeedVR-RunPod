from huggingface_hub import snapshot_download
import os

# Set the save directory
save_dir = "/workspace/SeedVR/ckpts/"
cache_dir = save_dir + "/cache"

# Create the directories if they don't exist
os.makedirs(save_dir, exist_ok=True)
os.makedirs(cache_dir, exist_ok=True)

# Models to download
models = [
    "ByteDance-Seed/SeedVR2-7B",
    "ByteDance-Seed/SeedVR2-3B"
]

# Download each model
for repo_id in models:
    print(f"Downloading model: {repo_id}")
    snapshot_download(
        cache_dir=cache_dir,
        local_dir=save_dir + repo_id.split('/')[-1],
        repo_id=repo_id,
        local_dir_use_symlinks=False,
        resume_download=True,
        allow_patterns=["*.json", "*.safetensors", "*.pth", "*.bin", "*.py", "*.md", "*.txt"],
    )

print("Model downloads complete.")
