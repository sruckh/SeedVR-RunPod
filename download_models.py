#!/usr/bin/env python3
"""
Model Download Script for SeedVR
Enhanced with robust retry logic and error handling
Downloads both SeedVR2-3B and SeedVR2-7B models from Hugging Face
"""

import os
import sys
import time
from pathlib import Path
from huggingface_hub import snapshot_download, login
import argparse
import logging

# Setup logging
logging.basicConfig(level=logging.INFO, format='%(message)s')
logger = logging.getLogger(__name__)

def check_hf_token():
    """Check if HF_TOKEN is available"""
    hf_token = os.getenv('HF_TOKEN')
    if hf_token:
        logger.info("🔐 Using HF_TOKEN for authentication")
        try:
            login(token=hf_token)
            return True
        except Exception as e:
            logger.error(f"❌ Failed to login with HF_TOKEN: {e}")
            return False
    else:
        logger.info("ℹ️  No HF_TOKEN provided, downloading public models only")
        return False

def check_model_exists(model_save_dir):
    """Check if model already exists and is complete"""
    if not os.path.exists(model_save_dir):
        return False
    
    # Check for key files that indicate a complete download
    required_files = ['config.json']
    model_files = os.listdir(model_save_dir)
    
    # Check if we have at least config.json and some model files
    has_config = any('config.json' in f for f in model_files)
    has_model_files = any(f.endswith(('.safetensors', '.pth', '.bin')) for f in model_files)
    
    if has_config and has_model_files:
        logger.info(f"✅ Model already exists at {model_save_dir}")
        return True
    
    return False

def download_with_retry(repo_id, model_save_dir, cache_dir, max_retries=5):
    """Download model with retry logic and exponential backoff"""
    
    for attempt in range(max_retries):
        try:
            logger.info(f"📥 Downloading {repo_id} (attempt {attempt + 1}/{max_retries})...")
            
            snapshot_download(
                cache_dir=cache_dir,
                local_dir=model_save_dir,
                repo_id=repo_id,
                local_dir_use_symlinks=False,
                resume_download=True,
                allow_patterns=[
                    "*.json", 
                    "*.safetensors", 
                    "*.pth", 
                    "*.bin", 
                    "*.py", 
                    "*.md", 
                    "*.txt",
                    "*.yaml",
                    "*.yml"
                ],
            )
            
            # Verify download completed successfully
            if check_model_exists(model_save_dir):
                logger.info(f"✅ Successfully downloaded {repo_id}")
                return True
            else:
                raise Exception("Download completed but model files are missing")
                
        except Exception as e:
            logger.error(f"❌ Download attempt {attempt + 1} failed: {str(e)}")
            
            if attempt < max_retries - 1:
                # Exponential backoff with jitter
                wait_time = min(300, (2 ** attempt) * 10)  # Cap at 5 minutes
                logger.info(f"⏳ Retrying in {wait_time} seconds...")
                time.sleep(wait_time)
            else:
                logger.error(f"❌ Failed to download {repo_id} after {max_retries} attempts")
                return False
    
    return False

def download_model(model_name, save_dir="/workspace/ckpts"):
    """Download a specific SeedVR model with enhanced error handling"""
    
    model_configs = {
        "3B": "ByteDance-Seed/SeedVR2-3B",
        "7B": "ByteDance-Seed/SeedVR2-7B"
    }
    
    if model_name not in model_configs:
        raise ValueError(f"Unknown model: {model_name}. Available: {list(model_configs.keys())}")
    
    repo_id = model_configs[model_name]
    model_save_dir = os.path.join(save_dir, model_name)
    cache_dir = os.path.join(save_dir, "cache", model_name)
    
    logger.info(f"📁 Model will be saved to: {model_save_dir}")
    
    # Create directories
    os.makedirs(model_save_dir, exist_ok=True)
    os.makedirs(cache_dir, exist_ok=True)
    
    # Check if model already exists
    if check_model_exists(model_save_dir):
        logger.info(f"✅ Model {model_name} already exists, skipping download")
        return True
    
    # Download with retry logic
    success = download_with_retry(repo_id, model_save_dir, cache_dir)
    
    if success:
        # Verify final download
        downloaded_files = os.listdir(model_save_dir)
        logger.info(f"📋 Downloaded files for {model_name}:")
        for f in sorted(downloaded_files)[:10]:  # Show first 10 files
            file_path = os.path.join(model_save_dir, f)
            if os.path.isfile(file_path):
                size_mb = os.path.getsize(file_path) / (1024 * 1024)
                logger.info(f"  {f} ({size_mb:.1f}MB)")
        
        if len(downloaded_files) > 10:
            logger.info(f"  ... and {len(downloaded_files) - 10} more files")
    
    return success

def main():
    parser = argparse.ArgumentParser(description="Download SeedVR models")
    parser.add_argument("--model", choices=["3B", "7B", "both"], default="both",
                       help="Which model to download (default: both)")
    parser.add_argument("--save-dir", default="/workspace/ckpts",
                       help="Directory to save models (default: /workspace/ckpts)")
    
    args = parser.parse_args()
    
    logger.info("🚀 Starting SeedVR model download...")
    
    # Check HF token and login if available
    check_hf_token()
    
    # Create save directory
    os.makedirs(args.save_dir, exist_ok=True)
    logger.info(f"📁 Models will be saved to: {args.save_dir}")
    
    success_count = 0
    total_count = 0
    failed_models = []
    
    models_to_download = []
    if args.model == "both":
        models_to_download = ["3B", "7B"]
    else:
        models_to_download = [args.model]
    
    for model in models_to_download:
        total_count += 1
        logger.info(f"\n{'='*50}")
        logger.info(f"Processing SeedVR2-{model} model")
        logger.info(f"{'='*50}")
        
        try:
            if download_model(model, args.save_dir):
                success_count += 1
                logger.info(f"✅ SeedVR2-{model} download completed successfully")
            else:
                failed_models.append(f"SeedVR2-{model}")
                logger.error(f"❌ SeedVR2-{model} download failed")
        except Exception as e:
            failed_models.append(f"SeedVR2-{model}")
            logger.error(f"❌ SeedVR2-{model} download failed with exception: {e}")
    
    # Final summary
    logger.info(f"\n{'='*50}")
    logger.info("📊 DOWNLOAD SUMMARY")
    logger.info(f"{'='*50}")
    logger.info(f"✅ Successful downloads: {success_count}/{total_count}")
    
    if failed_models:
        logger.error(f"❌ Failed downloads: {', '.join(failed_models)}")
    
    # Check available space
    try:
        import shutil
        total, used, free = shutil.disk_usage(args.save_dir)
        logger.info(f"💾 Storage: {free // (1024**3):.1f}GB free / {total // (1024**3):.1f}GB total")
    except:
        pass
    
    if success_count == total_count:
        logger.info("🎉 All models downloaded successfully!")
        logger.info("🚀 Ready to start SeedVR!")
        return 0
    else:
        logger.error("⚠️  Some models failed to download")
        logger.error("💡 Try running the script again - downloads will resume from where they left off")
        return 1

if __name__ == "__main__":
    sys.exit(main())