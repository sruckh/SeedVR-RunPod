#!/bin/bash
# This script is designed to be the entrypoint for the Docker container.
# It sets up the SeedVR environment from scratch at runtime.
set -e

echo "--- Starting SeedVR Runtime Setup ---"

# 1. Clone SeedVR repository
if [ -d "/workspace/SeedVR" ]; then
    echo "[1/9] SeedVR repository already exists. Skipping clone."
else
    echo "[1/9] Cloning SeedVR repository..."
    git clone https://github.com/ByteDance-Seed/SeedVR.git /workspace/SeedVR
fi
cd /workspace/SeedVR
echo "      Done."


# 2. Create and activate Python virtual environment
echo "[2/9] Setting up Python virtual environment..."
if [ -d "venv" ]; then
    echo "      Virtual environment already exists. Activating."
else
    python3 -m venv venv
fi
source venv/bin/activate
export PYTHONPATH="/workspace/SeedVR:$PYTHONPATH"
echo "      Done."

# 3. Install Python dependencies from the cloned repo
echo "[3/9] Installing dependencies from requirements.txt..."
pip install --upgrade pip
pip install -r requirements.txt

# Install PyAV for video operations in torchvision (missing from original requirements.txt)
echo "      Installing PyAV for video processing..."
pip install av
echo "      Done."

# 4. Install ByteDance flash-attention wheel (better GPU compatibility including L40)
echo "[4/9] Installing flash-attention wheel..."
pip install https://huggingface.co/ByteDance-Seed/SeedVR2-3B/resolve/main/flash_attn-2.5.8+cu121torch2.3cxx11abiFALSE-cp310-cp310-linux_x86_64.whl

echo "      Installing Gradio..."
pip install gradio
echo "      Done."

# 5. Install NVIDIA Apex from pre-built wheel
echo "[5/9] Installing NVIDIA Apex from pre-built wheel..."

# Re-activate virtual environment and set paths to ensure correct environment
echo "DEBUG: Re-activating virtual environment for APEX installation"
cd /workspace/SeedVR
source venv/bin/activate
export PYTHONPATH="/workspace/SeedVR:$PYTHONPATH"

# Debug virtual environment status
echo "DEBUG: Virtual environment status:"
echo "      Python executable: $(which python)"
echo "      Pip executable: $(which pip)"
echo "      Python version: $(python --version)"

# Install APEX from ByteDance pre-built wheel (no CUDA toolkit needed)
echo "      Installing APEX from pre-built wheel..."
pip install https://huggingface.co/ByteDance-Seed/SeedVR2-3B/resolve/main/apex-0.1-cp310-cp310-linux_x86_64.whl

# Verify APEX installation
echo "DEBUG: Verifying APEX installation in virtual environment..."
echo "DEBUG: Testing basic apex import..."
if python -c "import apex; print('APEX import successful')" 2>/dev/null; then
    echo "      ✅ APEX successfully installed and verified"
    echo "DEBUG: Testing FusedRMSNorm import..."
    if python -c "from apex.normalization import FusedRMSNorm; print('FusedRMSNorm import successful')" 2>/dev/null; then
        echo "      ✅ FusedRMSNorm available"
    else
        echo "      ⚠️  FusedRMSNorm not available - fallback will be used"
    fi
else
    echo "      ⚠️  APEX installation verification failed - fallback will be used"
fi

echo "      Done."

# 6. Model path configuration handled architecturally
echo "[6/9] Model path configuration..."
# Model paths are handled architecturally by download.py - no code patching needed
# This avoids timing issues where patches run before model files exist
echo "      Model paths handled architecturally in download process"
echo "      Done."

# 7. Place the color_fix.py utility into the project
echo "[7/9] Placing color_fix.py utility..."
# The file is copied into /workspace by the Dockerfile
# Place according to official SeedVR documentation: ./projects/video_diffusion_sr/color_fix.py

# Ensure we're in the SeedVR directory
cd /workspace/SeedVR

# Create directory structure and copy file
mkdir -p ./projects/video_diffusion_sr/
if [ -f "/workspace/color_fix.py" ]; then
    cp /workspace/color_fix.py ./projects/video_diffusion_sr/color_fix.py
    echo "      ✅ Placed color_fix.py at ./projects/video_diffusion_sr/color_fix.py"
    
    # Verify the file was placed correctly
    if [ -f "./projects/video_diffusion_sr/color_fix.py" ]; then
        echo "      ✅ Verified color_fix.py exists at correct location"
        ls -la ./projects/video_diffusion_sr/color_fix.py
    else
        echo "      ❌ ERROR: color_fix.py was not successfully copied"
    fi
else
    echo "      ❌ ERROR: Source file /workspace/color_fix.py not found"
    ls -la /workspace/color_fix.py
fi

echo "      Done."

# 8. Run the model download script
echo "[8/9] Downloading AI models (this may take a while)..."
# The script is copied into /workspace by the Dockerfile
# Make sure we're in the SeedVR directory so models download to ./ckpts
cd /workspace/SeedVR
python /workspace/download.py
echo "      Done."

# 9. Launch the Gradio web interface
echo "[9/9] Launching Gradio interface..."
# The script is copied into /workspace by the Dockerfile
# It will be served on port 7860 as configured in app.py
# Make sure we're in the SeedVR directory where projects/ folder exists
cd /workspace/SeedVR
python /workspace/app.py

echo "--- SeedVR Setup and Launch Complete ---"
