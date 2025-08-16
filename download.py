from huggingface_hub import snapshot_download
import os

def download_model(repo_id, save_dir):
    """
    Downloads a model from the Hugging Face Hub.
    """
    cache_dir = os.path.join(save_dir, "cache")
    snapshot_download(
        cache_dir=cache_dir,
        local_dir=save_dir,
        repo_id=repo_id,
        local_dir_use_symlinks=False,
        resume_download=True,
        allow_patterns=["*.json", "*.safetensors", "*.pth", "*.bin", "*.py", "*.md", "*.txt"],
    )

if __name__ == "__main__":
    # Create the main directory for checkpoints
    save_dir_base = "ckpts"
    if not os.path.exists(save_dir_base):
        os.makedirs(save_dir_base)

    # Download the 3B model
    repo_id_3b = "ByteDance-Seed/SeedVR2-3B"
    save_dir_3b = os.path.join(save_dir_base, "SeedVR2-3B")
    print(f"Downloading {repo_id_3b} to {save_dir_3b}...")
    download_model(repo_id_3b, save_dir_3b)
    print("Download complete.")

    # Download the 7B model
    repo_id_7b = "ByteDance-Seed/SeedVR2-7B"
    save_dir_7b = os.path.join(save_dir_base, "SeedVR2-7B")
    print(f"Downloading {repo_id_7b} to {save_dir_7b}...")
    download_model(repo_id_7b, save_dir_7b)
    print("Download complete.")