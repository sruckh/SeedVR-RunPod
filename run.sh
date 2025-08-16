#!/bin/bash

# Activate virtual environment
source /workspace/venv/bin/activate

# Install torch
pip install -r /workspace/requirements.txt

# Clone the repository
git clone https://github.com/ByteDance-Seed/SeedVR.git
cd SeedVR

# Download color_fix.py
wget https://raw.githubusercontent.com/pkuliyi2015/sd-webui-stablesr/master/srmodule/colorfix.py -O ./projects/video_diffusion_sr/color_fix.py

# Download the models
python3 /workspace/download.py

# Launch the Gradio web interface
python3 /workspace/app.py