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

    # ARCHITECTURAL FIXES: Copy model files to expected locations
    # Following successful VAE fix pattern - adapt environment to code expectations
    import shutil
    
    print("--- Applying architectural path fixes ---")
    
    # Fix 1: VAE model (already working)
    source_vae = "ckpts/SeedVR2-3B/ema_vae.pth"
    target_vae = "ckpts/ema_vae.pth"
    
    if os.path.exists(source_vae):
        shutil.copy2(source_vae, target_vae)
        print(f"--- Copied VAE file: {source_vae} -> {target_vae} ---")
        print("--- VAE model is now available at expected location ---")
    else:
        print(f"!!! VAE file not found at {source_vae} !!!")
        exit(1)

    # Fix 2: Main 3B model - inference_seedvr2_3b.py expects ./ckpts/seedvr2_ema_3b.pth
    source_3b = "ckpts/SeedVR2-3B/seedvr2_ema_3b.pth"
    target_3b = "ckpts/seedvr2_ema_3b.pth"
    
    if os.path.exists(source_3b):
        shutil.copy2(source_3b, target_3b)
        print(f"--- Copied 3B model: {source_3b} -> {target_3b} ---")
        print("--- 3B model is now available at expected location ---")
    else:
        print(f"!!! 3B model file not found at {source_3b} !!!")
        exit(1)

    # Fix 3: Main 7B model - inference_seedvr2_7b.py expects ./ckpts/seedvr2_ema_7b.pth  
    source_7b = "ckpts/SeedVR2-7B/seedvr2_ema_7b.pth"
    target_7b = "ckpts/seedvr2_ema_7b.pth"
    
    if os.path.exists(source_7b):
        shutil.copy2(source_7b, target_7b)
        print(f"--- Copied 7B model: {source_7b} -> {target_7b} ---")
        print("--- 7B model is now available at expected location ---")
    else:
        print(f"!!! 7B model file not found at {source_7b} !!!")
        exit(1)
        
    # Verify all expected model files now exist
    expected_files = [
        "ckpts/ema_vae.pth",
        "ckpts/seedvr2_ema_3b.pth", 
        "ckpts/seedvr2_ema_7b.pth"
    ]
    
    print("--- Verifying all model files are available at expected locations ---")
    all_files_exist = True
    for expected_file in expected_files:
        if os.path.exists(expected_file):
            file_size = os.path.getsize(expected_file) / (1024 * 1024)  # Size in MB
            print(f"✅ {expected_file} exists ({file_size:.1f} MB)")
        else:
            print(f"❌ {expected_file} MISSING")
            all_files_exist = False
    
    if not all_files_exist:
        print("!!! ERROR: Some model files are missing after architectural fixes !!!")
        exit(1)
        
    print("--- All architectural path fixes completed successfully ---")
    print("--- SeedVR inference scripts should now find all required model files ---")
    print("--- All models downloaded successfully! ---")