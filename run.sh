#!/bin/bash
# This script is designed to be the entrypoint for the Docker container.
# It sets up the SeedVR environment from scratch at runtime.
set -e

echo "--- Starting SeedVR Runtime Setup ---"

# 1. Clone SeedVR repository
if [ -d "/workspace/SeedVR" ]; then
    echo "[1/10] SeedVR repository already exists. Skipping clone."
else
    echo "[1/10] Cloning SeedVR repository..."
    git clone https://github.com/ByteDance-Seed/SeedVR.git /workspace/SeedVR
fi
cd /workspace/SeedVR
echo "      Done."


# 2. Create and activate Python virtual environment
echo "[2/10] Setting up Python virtual environment..."
if [ -d "venv" ]; then
    echo "      Virtual environment already exists. Activating."
else
    python3 -m venv venv
fi
source venv/bin/activate
export PYTHONPATH="/workspace/SeedVR:$PYTHONPATH"
echo "      Done."

# 3. Install Python dependencies from the cloned repo
echo "[3/10] Installing dependencies from requirements.txt..."
pip install --upgrade pip
pip install -r requirements.txt
echo "      Done."

# 4. Install the specific flash-attention wheel
echo "[4/10] Installing flash-attention wheel..."
pip install https://github.com/Dao-AILab/flash-attention/releases/download/v2.5.9.post1/flash_attn-2.5.9.post1+cu122torch2.3cxx11abiFALSE-cp310-cp310-linux_x86_64.whl

echo "      Installing Gradio..."
pip install gradio
echo "      Done."

# 5. Install CUDA toolkit and build NVIDIA Apex
echo "DEBUG: About to start CUDA/Apex installation step"
echo "[5/10] Installing CUDA toolkit and building NVIDIA Apex..."
echo "DEBUG: Starting CUDA/Apex installation section"

# Re-activate virtual environment and set paths to ensure correct environment
echo "DEBUG: Re-activating virtual environment for APEX installation"
cd /workspace/SeedVR
source venv/bin/activate
export PYTHONPATH="/workspace/SeedVR:$PYTHONPATH"
echo "DEBUG: Virtual environment status:"
echo "      Python executable: $(which python)"
echo "      Pip executable: $(which pip)"
echo "      PYTHONPATH: $PYTHONPATH"

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

# Now build Apex using virtual environment
echo "DEBUG: Checking if NVIDIA Apex is already installed in virtual environment..."
if /workspace/SeedVR/venv/bin/python -c "import apex" 2>/dev/null; then
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
if [ -d "/workspace/apex" ] && ! /workspace/SeedVR/venv/bin/python -c "import apex" 2>/dev/null; then
    echo "DEBUG: Proceeding with Apex installation from /workspace/apex"
    cd /workspace/apex
    
    # Check if CUDA is available for compilation
    if command -v nvcc &> /dev/null || [ -n "$CUDA_HOME" ]; then
        echo "      CUDA detected - attempting CUDA build"
        # Use environment variables to enable CUDA extensions as recommended by NVIDIA
        if ! timeout 1800 APEX_CPP_EXT=1 APEX_CUDA_EXT=1 /workspace/SeedVR/venv/bin/pip install -v --no-build-isolation --no-cache-dir ./; then
            echo "      WARNING: CUDA Apex build failed - falling back to Python-only build"
            # Try Python-only build as fallback
            if ! timeout 900 /workspace/SeedVR/venv/bin/pip install -v --no-build-isolation --no-cache-dir ./; then
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
        if ! timeout 900 /workspace/SeedVR/venv/bin/pip install -v --no-build-isolation --no-cache-dir ./; then
            echo "      ERROR: Python-only Apex build failed"
            echo "      Continuing without Apex - some optimizations may not be available"
        else
            echo "      Apex installed successfully (Python-only build)"
        fi
    fi
    
    # Return to SeedVR directory
    cd /workspace/SeedVR
fi
# Verify APEX installation in virtual environment
echo "DEBUG: Verifying APEX installation in virtual environment..."
cd /workspace/SeedVR
if /workspace/SeedVR/venv/bin/python -c "import apex; print(f'APEX version: {apex.__version__}'); from apex.normalization import FusedRMSNorm; print('FusedRMSNorm import successful')" 2>/dev/null; then
    echo "      ✅ APEX successfully installed and verified in virtual environment"
else
    echo "      ⚠️  APEX installation verification failed - will implement fallback in normalization code"
fi
echo "DEBUG: CUDA/Apex installation section completed"
echo "      Done."

# 6. Create APEX fallback implementation
echo "[6/10] Creating APEX fallback for missing dependencies..."

# Create APEX fallback Python module in SeedVR
cat > /workspace/SeedVR/apex_fallback.py << 'EOF'
"""
APEX Fallback Implementation for SeedVR
Provides compatible replacements when NVIDIA Apex is not available
"""
import torch
import torch.nn as nn
import sys
import types

def create_apex_fallback():
    """Create fallback APEX module structure"""
    print("Creating APEX fallback - NVIDIA Apex not available, using PyTorch alternatives")
    
    # Create mock apex module
    apex_module = types.ModuleType('apex')
    normalization_module = types.ModuleType('apex.normalization')
    
    class FusedRMSNorm(nn.Module):
        """Fallback RMSNorm when APEX FusedRMSNorm unavailable"""
        def __init__(self, normalized_shape, eps=1e-6, elementwise_affine=True, **kwargs):
            super().__init__()
            if isinstance(normalized_shape, int):
                normalized_shape = (normalized_shape,)
            self.normalized_shape = normalized_shape
            self.eps = eps
            self.elementwise_affine = elementwise_affine
            
            if self.elementwise_affine:
                self.weight = nn.Parameter(torch.ones(normalized_shape))
            else:
                self.register_buffer('weight', torch.ones(normalized_shape))
        
        def forward(self, input):
            # Standard RMSNorm: x / sqrt(mean(x^2) + eps) * weight
            input_dtype = input.dtype
            variance = input.to(torch.float32).pow(2).mean(-1, keepdim=True)
            input = input * torch.rsqrt(variance + self.eps)
            result = (input * self.weight.to(input.dtype)).to(input_dtype)
            return result
    
    # Add to modules
    normalization_module.FusedRMSNorm = FusedRMSNorm
    apex_module.normalization = normalization_module
    apex_module.__version__ = "fallback-1.0.0"
    
    # Inject into sys.modules
    sys.modules['apex'] = apex_module
    sys.modules['apex.normalization'] = normalization_module
    
    return True

# Auto-initialize fallback if apex import fails
try:
    import apex
    print("NVIDIA Apex found and loaded successfully")
except ImportError:
    create_apex_fallback()
    print("APEX fallback implementation loaded")
EOF

# Add fallback import to key SeedVR files that need APEX
echo "      Implementing APEX fallback in SeedVR normalization..."

# Patch the main normalization file to use fallback
if [ -f "/workspace/SeedVR/models/dit_v2/normalization.py" ]; then
    cp "/workspace/SeedVR/models/dit_v2/normalization.py" "/workspace/SeedVR/models/dit_v2/normalization.py.backup"
    sed -i '1i# Import APEX fallback before any APEX imports' "/workspace/SeedVR/models/dit_v2/normalization.py"
    sed -i '2i import sys, os' "/workspace/SeedVR/models/dit_v2/normalization.py"
    sed -i '3i sys.path.insert(0, "/workspace/SeedVR")' "/workspace/SeedVR/models/dit_v2/normalization.py"
    sed -i '4i import apex_fallback' "/workspace/SeedVR/models/dit_v2/normalization.py"
    sed -i '5i' "/workspace/SeedVR/models/dit_v2/normalization.py"
    echo "      Applied APEX fallback to normalization.py"
fi

# Create a general patch file for any Python file that imports apex
cat > /workspace/apex_import_patch.py << 'EOF'
import sys
import os
sys.path.insert(0, '/workspace/SeedVR')
try:
    import apex_fallback
except ImportError:
    pass
EOF

echo "      APEX fallback implementation created"
echo "      Done."

# 7. Patch inference scripts to point to correct model paths  
echo "[7/10] Patching inference scripts for correct model paths..."
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

# 8. Place the color_fix.py utility into the project
echo "[8/10] Placing color_fix.py utility..."
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

# 9. Run the model download script
echo "[9/10] Downloading AI models (this may take a while)..."
# The script is copied into /workspace by the Dockerfile
# Make sure we're in the SeedVR directory so models download to ./ckpts
cd /workspace/SeedVR
python /workspace/download.py
echo "      Done."

# 10. Launch the Gradio web interface
echo "[10/10] Launching Gradio interface..."
# The script is copied into /workspace by the Dockerfile
# It will be served on port 7860 as configured in app.py
# Make sure we're in the SeedVR directory where projects/ folder exists
cd /workspace/SeedVR
python /workspace/app.py

echo "--- SeedVR Setup and Launch Complete ---"
