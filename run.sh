#!/bin/bash
# This script is designed to be the entrypoint for the Docker container.
# It sets up the SeedVR environment from scratch at runtime.
set -e

echo "--- Starting SeedVR Runtime Setup ---"

# 1. Clone SeedVR repository
if [ -d "/workspace/SeedVR" ]; then
    echo "[1/8] SeedVR repository already exists. Skipping clone."
else
    echo "[1/8] Cloning SeedVR repository..."
    git clone https://github.com/ByteDance-Seed/SeedVR.git /workspace/SeedVR
fi
cd /workspace/SeedVR
echo "      Done."


# 2. Create and activate Python virtual environment
echo "[2/8] Setting up Python virtual environment..."
if [ -d "venv" ]; then
    echo "      Virtual environment already exists. Activating."
else
    python3 -m venv venv
fi
source venv/bin/activate
echo "      Done."

# 3. Install Python dependencies from the cloned repo
echo "[3/8] Installing dependencies from requirements.txt..."
pip install --upgrade pip
pip install -r requirements.txt
echo "      Done."

# 4. Install the specific flash-attention wheel
echo "[4/8] Installing flash-attention wheel..."
pip install https://github.com/Dao-AILab/flash-attention/releases/download/v2.5.9.post1/flash_attn-2.5.9.post1+cu122torch2.4cxx11abiFALSE-cp310-cp310-linux_x86_64.whl
echo "      Done."

# 5. Patch inference scripts to point to correct model paths
echo "[5/8] Patching inference scripts for correct model paths..."
sed -i 's|\./ckpts/seedvr2_ema_3b\.pth|\./ckpts/SeedVR2-3B/seedvr2_ema_3b.pth|g' projects/inference_seedvr2_3b.py
sed -i 's|\./ckpts/seedvr2_ema_7b\.pth|\./ckpts/SeedVR2-7B/seedvr2_ema_7b.pth|g' projects/inference_seedvr2_7b.py
echo "      Done."

# 6. Place the color_fix.py utility into the project
echo "[6/8] Placing color_fix.py utility..."
# The file is copied into /workspace by the Dockerfile
mkdir -p ./projects/video_diffusion_sr/
cp /workspace/color_fix.py ./projects/video_diffusion_sr/color_fix.py
echo "      Done."

# 7. Run the model download script
echo "[7/8] Downloading AI models (this may take a while)..."
# The script is copied into /workspace by the Dockerfile
python /workspace/download.py
echo "      Done."

# 8. Launch the Gradio web interface
echo "[8/8] Launching Gradio interface..."
# The script is copied into /workspace by the Dockerfile
# It will be served on port 7860 as configured in app.py
python /workspace/app.py

echo "--- SeedVR Setup and Launch Complete ---"
