#!/bin/bash

1
1# Exit on error
set -e

# 1. Create a python 3.10 virtual environment
echo "Creating Python 3.10 virtual environment..."
apt-get update && apt-get install -y python3.10 python3.10-venv git
python3.10 -m venv /workspace/venv
source /workspace/venv/bin/activate

# 2. Install Torch
echo "Installing Torch..."
pip install torch==2.7.0 torchvision==0.22.0 torchaudio==2.7.0

# 3. Install flash-attn
echo "Installing flash-attention..."
pip install https://github.com/Dao-AILab/flash-attention/releases/download/v2.8.3/flash_attn-2.8.3+cu12torch2.7cxx11abiFALSE-cp311-cp311-linux_x86_64.whl

# 4. Clone the SeedVR git repository
echo "Cloning SeedVR repository..."
git clone https://github.com/ByteDance-Seed/SeedVR.git /workspace/SeedVR

# 5. Change the working directory
cd /workspace/SeedVR

# 6. Install requirements.txt
echo "Installing requirements..."
pip install -r requirements.txt

# 7. Install apex
echo "Installing apex..."
pip install https://huggingface.co/ByteDance-Seed/SeedVR2-3B/resolve/main/apex-0.1-cp310-cp310-linux_x86_64.whl

# 8. Copy color_fix.py
echo "Copying color_fix.py..."
cp /app/color_fix.py ./projects/video_diffusion_sr/color_fix.py

1# 9. Copy modified inference scripts
echo "Copying modified inference scripts..."
cp /app/inference_seedvr2_3b_modified.py /workspace/SeedVR/projects/inference_seedvr2_3b.py
cp /app/inference_seedvr2_7b_modified.py /workspace/SeedVR/projects/inference_seedvr2_7b.py

# 10. Download models
echo "Downloading models..."
python /app/download.py

# 11. Launch Gradio app
echo "Launching Gradio app..."
python /app/app.py
