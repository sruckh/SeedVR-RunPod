#!/bin/bash
# This script is designed to be the entrypoint for the Docker container.
# It sets up the SeedVR environment from scratch at runtime.
set -e

echo "--- Starting SeedVR Runtime Setup ---"

# 1. Clone SeedVR repository
if [ -d "/workspace/SeedVR" ]; then
    echo "[1/7] SeedVR repository already exists. Skipping clone."
else
    echo "[1/7] Cloning SeedVR repository..."
    git clone https://github.com/ByteDance-Seed/SeedVR.git /workspace/SeedVR
fi
cd /workspace/SeedVR
echo "      Done."


# 2. Create and activate Python virtual environment
echo "[2/7] Setting up Python virtual environment..."
if [ -d "venv" ]; then
    echo "      Virtual environment already exists. Activating."
else
    python3 -m venv venv
fi
source venv/bin/activate
echo "      Done."

# 3. Install Python dependencies from the cloned repo
echo "[3/7] Installing dependencies from requirements.txt..."
pip install --upgrade pip
pip install -r requirements.txt
echo "      Done."

# 4. Install the specific flash-attention wheel
echo "[4/7] Installing flash-attention wheel..."
pip install https://github.com/Dao-AILab/flash-attention/releases/download/v2.5.9.post1/flash_attn-2.5.9.post1+cu122torch2.4cxx11abiFALSE-cp310-cp310-linux_x86_64.whl
echo "      Done."

# 5. Place the color_fix.py utility into the project
echo "[5/7] Placing color_fix.py utility..."
# The file is copied into /workspace by the Dockerfile
mkdir -p ./projects/video_diffusion_sr/
cp /workspace/color_fix.py ./projects/video_diffusion_sr/color_fix.py
echo "      Done."

# 6. Run the model download script
echo "[6/7] Downloading AI models (this may take a while)..."
# The script is copied into /workspace by the Dockerfile
python /workspace/download.py
echo "      Done."

# 7. Launch the Gradio web interface
echo "[7/7] Launching Gradio interface..."
# The script is copied into /workspace by the Dockerfile
# It will be served on port 7860 as configured in app.py
python /workspace/app.py

echo "--- SeedVR Setup and Launch Complete ---"
