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
echo "      Done."

# 4. Install the specific flash-attention wheel
echo "[4/9] Installing flash-attention wheel..."
pip install https://github.com/Dao-AILab/flash-attention/releases/download/v2.5.9.post1/flash_attn-2.5.9.post1+cu122torch2.3cxx11abiFALSE-cp310-cp310-linux_x86_64.whl

echo "      Installing Gradio..."
pip install gradio
echo "      Done."

# 5. Install CUDA toolkit and build NVIDIA Apex
echo "DEBUG: About to start CUDA/Apex installation step"
echo "[5/9] Installing CUDA toolkit and building NVIDIA Apex..."
echo "DEBUG: Starting CUDA/Apex installation section"

# First, install CUDA toolkit if not already present
echo "DEBUG: Checking for nvcc command..."
if ! command -v nvcc &> /dev/null; then
    echo "DEBUG: nvcc not found, will install CUDA toolkit"
    echo "      Installing CUDA toolkit..."
    apt-get update
    # Install minimal CUDA components to avoid dependency conflicts
    if wget -q https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2004/x86_64/cuda-keyring_1.0-1_all.deb && \
       dpkg -i cuda-keyring_1.0-1_all.deb && \
       apt-get update && \
       (apt-get install -y cuda-compiler-12-1 cuda-libraries-dev-12-1 cuda-driver-dev-12-1 || \
        apt-get install -y --no-install-recommends cuda-toolkit-12-1-config-common cuda-compiler-12-1 cuda-libraries-dev-12-1) && \
       rm cuda-keyring_1.0-1_all.deb; then
        echo "      CUDA toolkit installed successfully"
        export CUDA_HOME=/usr/local/cuda
        export PATH=${CUDA_HOME}/bin:${PATH}
        export LD_LIBRARY_PATH=${CUDA_HOME}/lib64:${LD_LIBRARY_PATH}
    else
        echo "      WARNING: CUDA toolkit installation failed"
        echo "      Continuing with host CUDA (if available) or Python-only Apex build"
    fi
else
    echo "DEBUG: nvcc found, CUDA toolkit already available"
    echo "      CUDA toolkit already available"
fi

# Now build Apex
echo "DEBUG: Checking if NVIDIA Apex is already installed..."
if python -c "import apex" 2>/dev/null; then
    echo "DEBUG: NVIDIA Apex already installed, skipping entire installation"
    echo "      NVIDIA Apex already installed. Skipping."
elif [ -d "/workspace/apex" ]; then
    echo "DEBUG: /workspace/apex exists but Apex not installed, will build from existing repo"
    echo "      Apex repository exists. Building from existing source..."
    cd /workspace/apex
    echo "      Building Apex with CUDA extensions (this may take several minutes)..."
else
    echo "DEBUG: /workspace/apex does not exist and Apex not installed, will clone and build"
    echo "      Cloning NVIDIA Apex repository..."
    if ! git clone https://github.com/NVIDIA/apex.git /workspace/apex; then
        echo "      ERROR: Failed to clone NVIDIA Apex repository"
        echo "      Continuing without Apex - some optimizations may not be available"
    else
        cd /workspace/apex
        echo "      Building Apex with CUDA extensions (this may take several minutes)..."
    fi
fi

# If we have the apex directory (either existing or newly cloned), proceed with installation
if [ -d "/workspace/apex" ] && ! python -c "import apex" 2>/dev/null; then
    echo "DEBUG: Proceeding with Apex installation from /workspace/apex"
    cd /workspace/apex
    
    # Check if CUDA is available for compilation
    if command -v nvcc &> /dev/null || [ -n "$CUDA_HOME" ]; then
        echo "      CUDA detected - attempting CUDA build"
        # Use environment variables to enable CUDA extensions as recommended by NVIDIA
        if ! timeout 1800 APEX_CPP_EXT=1 APEX_CUDA_EXT=1 pip install -v --no-build-isolation --no-cache-dir ./; then
            echo "      WARNING: CUDA Apex build failed - falling back to Python-only build"
            # Try Python-only build as fallback
            if ! timeout 900 pip install -v --no-build-isolation --no-cache-dir ./; then
                echo "      ERROR: Both CUDA and Python-only Apex builds failed"
                echo "      Continuing without Apex - some optimizations may not be available"
            else
                echo "      Apex installed successfully (Python-only build)"
            fi
        else
            echo "      Apex installed successfully with CUDA extensions"
        fi
    else
        echo "      No CUDA detected - using Python-only build"
        if ! timeout 900 pip install -v --no-build-isolation --no-cache-dir ./; then
            echo "      ERROR: Python-only Apex build failed"
            echo "      Continuing without Apex - some optimizations may not be available"
        else
            echo "      Apex installed successfully (Python-only build)"
        fi
    fi
    
    # Return to SeedVR directory
    cd /workspace/SeedVR
fi
echo "DEBUG: CUDA/Apex installation section completed"
echo "      Done."

# 6. Patch inference scripts to point to correct model paths
echo "[6/9] Patching inference scripts for correct model paths..."
if [ -f "projects/inference_seedvr2_3b.py" ]; then
    sed -i 's|\./ckpts/seedvr2_ema_3b\.pth|\./ckpts/SeedVR2-3B/seedvr2_ema_3b.pth|g' projects/inference_seedvr2_3b.py
    echo "      Patched inference_seedvr2_3b.py"
else
    echo "      WARNING: projects/inference_seedvr2_3b.py not found, skipping patch"
fi
if [ -f "projects/inference_seedvr2_7b.py" ]; then
    sed -i 's|\./ckpts/seedvr2_ema_7b\.pth|\./ckpts/SeedVR2-7B/seedvr2_ema_7b.pth|g' projects/inference_seedvr2_7b.py
    echo "      Patched inference_seedvr2_7b.py"
else
    echo "      WARNING: projects/inference_seedvr2_7b.py not found, skipping patch"
fi
echo "      Done."

# 6. Place the color_fix.py utility into the project
echo "[7/9] Placing color_fix.py utility..."
# The file is copied into /workspace by the Dockerfile
mkdir -p ./projects/video_diffusion_sr/
cp /workspace/color_fix.py ./projects/video_diffusion_sr/color_fix.py
echo "      Done."

# 7. Run the model download script
echo "[8/9] Downloading AI models (this may take a while)..."
# The script is copied into /workspace by the Dockerfile
python /workspace/download.py
echo "      Done."

# 8. Launch the Gradio web interface
echo "[9/9] Launching Gradio interface..."
# The script is copied into /workspace by the Dockerfile
# It will be served on port 7860 as configured in app.py
python /workspace/app.py

echo "--- SeedVR Setup and Launch Complete ---"
