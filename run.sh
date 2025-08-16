#!/bin/bash

# Activate virtual environment
source /workspace/venv/bin/activate

# Install torch
pip install torch==2.7.0 torchvision==0.22.0 torchaudio==2.7.0

# Install flash-attn
pip install https://github.com/Dao-AILab/flash-attention/releases/download/v2.8.3/flash_attn-2.8.3+cu12torch2.7cxx11abiFALSE-cp311-cp311-linux_x86_64.whl

# Clone the repository
git clone https://github.com/ByteDance-Seed/SeedVR.git
cd SeedVR

# Install requirements
pip install -r requirements.txt

# Install apex
pip install https://huggingface.co/ByteDance-Seed/SeedVR2-3B/resolve/main/apex-0.1-cp310-cp310-linux_x86_64.whl --no-deps

# Download color_fix.py
wget https://raw.githubusercontent.com/pkuliyi2015/sd-webui-stablesr/master/srmodule/colorfix.py -O ./projects/video_diffusion_sr/color_fix.py

# Install huggingface_hub for downloading models
pip install huggingface_hub

# Download the models
python3 /workspace/download.py

# Install huggingface_hub for downloading models
pip install huggingface_hub

# Download the models
python3 /workspace/download.py

# Install gradio for the web interface
pip install gradio

# Launch the Gradio web interface
python3 /workspace/app.py