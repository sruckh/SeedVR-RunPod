import os
from huggingface_hub import snapshot_download

def download_model(repo_id, local_dir_name):
    """Downloads a model from Hugging Face Hub."""
    save_dir = "ckpts"
    local_dir = os.path.join(save_dir, local_dir_name)

    print(f"--- Downloading model: {repo_id} ---")
    print(f"Saving to: {local_dir}")

    try:
        snapshot_download(
            repo_id=repo_id,
            local_dir=local_dir,
            allow_patterns=["*.json", "*.safetensors", "*.pth", "*.bin", "*.py", "*.md", "*.txt", "*.yaml", "*.yml"],
        )
        print(f"--- Successfully downloaded {repo_id} ---")
    except Exception as e:
        print(f"!!! Failed to download {repo_id}. Error: {e} !!!")
        # Exit with an error code if a download fails
        exit(1)

if __name__ == "__main__":
    print("--- Starting model download process ---")

    # Model repository IDs
    model_3b_repo = "ByteDance-Seed/SeedVR2-3B"
    model_7b_repo = "ByteDance-Seed/SeedVR2-7B"

    # Download both models
    download_model(model_3b_repo, "SeedVR2-3B")
    download_model(model_7b_repo, "SeedVR2-7B")

    # ARCHITECTURAL FIX: Copy VAE file to expected location
    # The VAE file is identical between 3B and 7B models, so we copy it once
    # to where the original code expects it: ./ckpts/ema_vae.pth
    import shutil
    source_vae = "ckpts/SeedVR2-3B/ema_vae.pth"
    target_vae = "ckpts/ema_vae.pth"
    
    if os.path.exists(source_vae):
        shutil.copy2(source_vae, target_vae)
        print(f"--- Copied VAE file: {source_vae} -> {target_vae} ---")
        print("--- VAE model is now available at expected location ---")
    else:
        print(f"!!! VAE file not found at {source_vae} !!!")
        exit(1)

    print("--- All models downloaded successfully! ---")