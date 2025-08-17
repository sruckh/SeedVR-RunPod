#!/bin/bash

# Exit on error
set -e

# 1. Install Python 3.10
echo "Installing Python 3.10..."
export DEBIAN_FRONTEND=noninteractive
apt-get update && apt-get install -y --no-install-recommends software-properties-common
add-apt-repository -y ppa:deadsnakes/ppa
apt-get update && apt-get install -y --no-install-recommends python3.10 python3.10-venv git

# 2. Create a python 3.10 virtual environment
echo "Creating Python 3.10 virtual environment..."
python3.10 -m venv /workspace/venv
source /workspace/venv/bin/activate

# 3. Clone the SeedVR git repository
echo "Cloning SeedVR repository..."
if [ -d "/workspace/SeedVR" ] && [ "$(ls -A /workspace/SeedVR)" ]; then
    echo "SeedVR directory already exists and is not empty. Skipping clone."
else
    git clone https://github.com/ByteDance-Seed/SeedVR.git /workspace/SeedVR
fi

# 4. Change the working directory
cd /workspace/SeedVR

# 5. Install requirements
echo "Installing requirements..."
pip install -r /app/requirements.txt

# 6. Install flash-attn
echo "Installing flash-attention..."
pip install flash_attn==2.5.9.post1 --no-build-isolation

# 7. Install apex
echo "Installing apex..."
pip install https://huggingface.co/ByteDance-Seed/SeedVR2-3B/resolve/main/apex-0.1-cp310-cp310-linux_x86_64.whl

# 8. Copy color_fix.py
echo "Copying color_fix.py..."
cp /app/color_fix.py ./projects/video_diffusion_sr/color_fix.py

# 9. Copy modified inference scripts
echo "Copying modified inference scripts..."
cp /app/inference_seedvr2_3b_modified.py /workspace/SeedVR/projects/inference_seedvr2_3b.py
cp /app/inference_seedvr2_7b_modified.py /workspace/SeedVR/projects/inference_seedvr2_7b.py

# 10. Download models
echo "Downloading models..."
python /app/download.py

# 11. Launch Gradio app
echo "Launching Gradio app..."
python /app/app.py