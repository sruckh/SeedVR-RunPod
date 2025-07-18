#!/bin/bash

# SeedVR Environment Setup Script for RunPod
# Enhanced with robust error checking and retry logic
# Based on patterns from OmniAvatar implementation

set -e

echo "🚀 Starting SeedVR environment setup..."

# Function to verify GPU setup
verify_gpu_setup() {
    echo "🔍 Final GPU verification:"
    python -c "
import torch
import os
print(f'PyTorch version: {torch.__version__}')
print(f'CUDA available: {torch.cuda.is_available()}')
if torch.cuda.is_available():
    print(f'CUDA version: {torch.version.cuda}')
    print(f'GPU count: {torch.cuda.device_count()}')
    for i in range(torch.cuda.device_count()):
        props = torch.cuda.get_device_properties(i)
        print(f'GPU {i}: {torch.cuda.get_device_name(i)} ({props.total_memory / 1024**3:.1f}GB)')
    # Test GPU operations
    try:
        device = torch.cuda.current_device()
        x = torch.randn(100, 100).cuda()
        y = torch.randn(100, 100).cuda()
        z = torch.matmul(x, y)
        print(f'✅ GPU tensor operations working: {z.shape} on {z.device}')
    except Exception as e:
        print(f'❌ GPU operations failed: {e}')
        exit(1)
else:
    print('❌ No GPU detected - SeedVR requires GPU')
    exit(1)
"
}

# Check if already setup
if [ -f "/workspace/.setup_complete" ]; then
    echo "✅ Environment already set up, skipping package installation..."
    
    # Always ensure SeedVR source files are available
    if [ ! -f "/workspace/projects/inference_seedvr2_3b.py" ] || [ ! -f "/workspace/projects/inference_seedvr2_7b.py" ]; then
        echo "📥 SeedVR source files missing, downloading..."
        # Clone SeedVR repository if not exists
        if [ ! -d "/workspace/SeedVR" ]; then
            git clone https://github.com/bytedance-seed/SeedVR.git /workspace/SeedVR
        fi
        # Copy SeedVR source files to workspace
        echo "📂 Copying SeedVR source files..."
        cp -r /workspace/SeedVR/* /workspace/ 2>/dev/null || true
    fi
    
    # Still verify CUDA setup
    verify_gpu_setup
    exit 0
fi

# Function to verify PyTorch and CUDA setup
verify_pytorch_cuda() {
    echo "🔍 Verifying PyTorch and CUDA setup..."
    python -c "
import torch
import os
print(f'PyTorch version: {torch.__version__}')
print(f'CUDA available: {torch.cuda.is_available()}')
print(f'Environment variables:')
print(f'  CUDA_VISIBLE_DEVICES: {os.environ.get(\"CUDA_VISIBLE_DEVICES\", \"Not set\")}')
if torch.cuda.is_available():
    print(f'CUDA version: {torch.version.cuda}')
    print(f'GPU count: {torch.cuda.device_count()}')
    for i in range(torch.cuda.device_count()):
        print(f'GPU {i}: {torch.cuda.get_device_name(i)}')
        print(f'GPU {i} memory: {torch.cuda.get_device_properties(i).total_memory / 1024**3:.1f}GB')
    print(f'Current GPU: {torch.cuda.current_device()}')
    # Test actual GPU operations
    try:
        x = torch.randn(1000, 1000).cuda()
        y = torch.mm(x, x.t())
        print(f'✅ GPU operations working: {y.shape} on {y.device}')
    except Exception as e:
        print(f'❌ GPU operations failed: {e}')
        exit(1)
else:
    print('❌ No GPU detected - SeedVR requires GPU for inference')
    exit(1)
"
}

# Function to install PyTorch if needed
install_pytorch() {
    echo "🔍 Checking PyTorch installation..."
    if python -c "import torch; print(f'PyTorch {torch.__version__} (CUDA available: {torch.cuda.is_available()})')" 2>/dev/null; then
        echo "✅ PyTorch is already installed"
        return 0
    else
        echo "📥 Installing PyTorch with CUDA 12.1 support..."
        local pytorch_url="https://download.pytorch.org/whl/cu121"
        local max_retries=3
        local retry_count=0
        
        while [ $retry_count -lt $max_retries ]; do
            echo "📥 Installing PyTorch (attempt $((retry_count + 1))/$max_retries)..."
            
            if pip install --no-cache-dir torch==2.4.0 torchvision==0.19.0 torchaudio==2.4.0 --index-url "$pytorch_url"; then
                echo "✅ PyTorch installed successfully"
                verify_pytorch_cuda
                return 0
            else
                retry_count=$((retry_count + 1))
                if [ $retry_count -lt $max_retries ]; then
                    echo "⚠️  PyTorch installation failed, retrying in 10s..."
                    sleep 10
                else
                    echo "❌ Failed to install PyTorch after $max_retries attempts"
                    exit 1
                fi
            fi
        done
    fi
}

# Function to install flash_attn with enhanced error checking
install_flash_attn() {
    echo "🔍 Checking for flash_attn..."
    if python -c "import flash_attn; print('flash_attn version:', flash_attn.__version__)" 2>/dev/null; then
        echo "✅ flash_attn is already installed"
        return 0
    else
        echo "📥 Installing flash_attn..."
        local flash_attn_url="https://github.com/Dao-AILab/flash-attention/releases/download/v2.5.9.post1/flash_attn-2.5.9.post1+cu122torch2.4cxx11abiFALSE-cp310-cp310-linux_x86_64.whl"
        local max_retries=3
        local retry_count=0
        
        # Check if cached wheel exists first
        local cached_wheel="/workspace/cache/flash_attn-2.5.9.post1+cu122torch2.4cxx11abiFALSE-cp310-cp310-linux_x86_64.whl"
        mkdir -p /workspace/cache
        
        if [ -f "$cached_wheel" ]; then
            echo "✅ Found cached flash_attn wheel, installing..."
            if pip install --no-cache-dir "$cached_wheel" --no-build-isolation; then
                echo "✅ flash_attn installed successfully from cache"
                return 0
            else
                echo "⚠️  Failed to install from cache, downloading..."
            fi
        fi
        
        # Download and install if not cached or cache failed
        while [ $retry_count -lt $max_retries ]; do
            echo "📥 Downloading flash_attn wheel (attempt $((retry_count + 1))/$max_retries)..."
            
            local wheel_filename="flash_attn-2.5.9.post1+cu122torch2.4cxx11abiFALSE-cp310-cp310-linux_x86_64.whl"
            if wget -q --timeout=300 -O "/tmp/$wheel_filename" "$flash_attn_url" && \
               cp "/tmp/$wheel_filename" "$cached_wheel" && \
               pip install --no-cache-dir "/tmp/$wheel_filename" --no-build-isolation && \
               rm -f "/tmp/$wheel_filename"; then
                echo "✅ flash_attn installed and cached successfully"
                return 0
            else
                retry_count=$((retry_count + 1))
                if [ $retry_count -lt $max_retries ]; then
                    echo "⚠️  flash_attn installation failed, retrying in 10s..."
                    sleep 10
                else
                    echo "❌ Failed to install flash_attn after $max_retries attempts"
                    echo "⚠️  Continuing without flash_attn (performance may be slower)"
                    return 1
                fi
            fi
        done
    fi
}

# Function to install apex with enhanced error checking
install_apex() {
    echo "🔍 Checking for apex..."
    if python -c "import apex; print('apex installed successfully')" 2>/dev/null; then
        echo "✅ apex is already installed"
        return 0
    else
        echo "📥 Installing apex..."
        local apex_url="https://huggingface.co/ByteDance-Seed/SeedVR2-3B/resolve/main/apex-0.1-cp310-cp310-linux_x86_64.whl"
        local max_retries=3
        local retry_count=0
        
        # Check if cached wheel exists first
        local cached_wheel="/workspace/cache/apex-0.1-cp310-cp310-linux_x86_64.whl"
        mkdir -p /workspace/cache
        
        if [ -f "$cached_wheel" ]; then
            echo "✅ Found cached apex wheel, installing..."
            if pip install --no-cache-dir "$cached_wheel"; then
                echo "✅ apex installed successfully from cache"
                return 0
            else
                echo "⚠️  Failed to install from cache, downloading..."
            fi
        fi
        
        # Download and install if not cached or cache failed
        while [ $retry_count -lt $max_retries ]; do
            echo "📥 Downloading apex wheel (attempt $((retry_count + 1))/$max_retries)..."
            
            local wheel_filename="apex-0.1-cp310-cp310-linux_x86_64.whl"
            if wget -q --timeout=300 -O "/tmp/$wheel_filename" "$apex_url" && \
               cp "/tmp/$wheel_filename" "$cached_wheel" && \
               pip install --no-cache-dir "/tmp/$wheel_filename" && \
               rm -f "/tmp/$wheel_filename"; then
                echo "✅ apex installed and cached successfully"
                return 0
            else
                retry_count=$((retry_count + 1))
                if [ $retry_count -lt $max_retries ]; then
                    echo "⚠️  apex installation failed, retrying in 10s..."
                    sleep 10
                else
                    echo "❌ Failed to install apex after $max_retries attempts"
                    echo "⚠️  Continuing without apex (some features may not work)"
                    return 1
                fi
            fi
        done
    fi
}

# Function to setup GPU environment variables
setup_gpu_environment() {
    echo "🔧 Setting up GPU environment variables..."
    export RANK=0
    export LOCAL_RANK=0
    export WORLD_SIZE=1
    export NNODES=1
    export CUDA_VISIBLE_DEVICES=${CUDA_VISIBLE_DEVICES:-0}
    
    echo "Environment variables set:"
    echo "  CUDA_VISIBLE_DEVICES: $CUDA_VISIBLE_DEVICES"
    echo "  RANK: $RANK"
    echo "  LOCAL_RANK: $LOCAL_RANK"
    echo "  WORLD_SIZE: $WORLD_SIZE"
}

# Main setup sequence
echo "📁 Creating workspace directories..."
mkdir -p /workspace/cache /workspace/temp /workspace/outputs /workspace/ckpts

# Clone SeedVR repository if not exists
if [ ! -d "/workspace/SeedVR" ]; then
    echo "📥 Cloning SeedVR repository..."
    git clone https://github.com/bytedance-seed/SeedVR.git /workspace/SeedVR
fi

# Copy SeedVR source files to workspace with proper structure
echo "📂 Copying SeedVR source files..."
cp -r /workspace/SeedVR/* /workspace/ 2>/dev/null || true

# Ensure proper Python path structure
echo "🔧 Setting up Python module structure..."
# Add /workspace to Python path for imports
export PYTHONPATH="/workspace:$PYTHONPATH"

# Verify inference scripts are available in projects directory
echo "🔍 Verifying inference scripts in projects directory..."
if [ -f "/workspace/projects/inference_seedvr2_3b.py" ] && [ -f "/workspace/projects/inference_seedvr2_7b.py" ]; then
    echo "✅ Both inference scripts are available in /workspace/projects/"
else
    echo "❌ Missing inference scripts in /workspace/projects/:"
    [ ! -f "/workspace/projects/inference_seedvr2_3b.py" ] && echo "  - inference_seedvr2_3b.py"
    [ ! -f "/workspace/projects/inference_seedvr2_7b.py" ] && echo "  - inference_seedvr2_7b.py"
fi

# Verify models directory exists
echo "🔍 Verifying models directory structure..."
if [ -d "/workspace/models" ]; then
    echo "✅ Models directory exists at /workspace/models"
    ls -la /workspace/models/ | head -10
else
    echo "❌ Models directory not found at /workspace/models"
    echo "📋 Available directories in /workspace:"
    ls -la /workspace/ | grep "^d"
fi

# Ensure all necessary directories from SeedVR are available
echo "🔧 Ensuring complete SeedVR structure is available..."
for dir in models data scripts configs utils; do
    if [ -d "/workspace/SeedVR/$dir" ] && [ ! -d "/workspace/$dir" ]; then
        echo "📂 Copying $dir directory to workspace..."
        cp -r "/workspace/SeedVR/$dir" "/workspace/$dir"
    fi
done

# Ensure __init__.py files exist for Python imports
echo "🔧 Adding __init__.py files for Python imports..."
for dir in models data scripts configs utils; do
    if [ -d "/workspace/$dir" ] && [ ! -f "/workspace/$dir/__init__.py" ]; then
        touch "/workspace/$dir/__init__.py"
    fi
done

# Final verification of critical files
echo "🔍 Final verification of critical files..."
echo "  - /workspace/projects/: $(ls -la /workspace/projects/ 2>/dev/null | wc -l) files"
echo "  - /workspace/models/: $(ls -la /workspace/models/ 2>/dev/null | wc -l) files"
echo "  - /workspace/: $(ls -la /workspace/ 2>/dev/null | wc -l) total files"

# Setup GPU environment
setup_gpu_environment

# Install PyTorch first (required for other packages)
install_pytorch

# Install flash_attn for performance optimization
install_flash_attn

# Install apex
install_apex

# Download color fix utility if not exists
if [ ! -f "/workspace/projects/video_diffusion_sr/color_fix.py" ]; then
    echo "🎨 Downloading color fix utility..."
    mkdir -p /workspace/projects/video_diffusion_sr
    wget -O /workspace/projects/video_diffusion_sr/color_fix.py https://raw.githubusercontent.com/pkuliyi2015/sd-webui-stablesr/master/srmodule/colorfix.py || echo "⚠️  Color fix download failed, continuing..."
fi

# Run model download script
echo "🤖 Downloading models..."
python /workspace/download_models.py

# Final verification
verify_gpu_setup

# Create environment file for persistent settings
echo "📝 Creating environment configuration..."
cat > /workspace/.env << 'EOF'
export PYTHONPATH="/workspace:$PYTHONPATH"
export CUDA_VISIBLE_DEVICES=${CUDA_VISIBLE_DEVICES:-0}
export RANK=0
export LOCAL_RANK=0
export WORLD_SIZE=1
export NNODES=1
EOF

# Mark setup as complete
touch /workspace/.setup_complete

echo "✅ SeedVR environment setup complete!"
echo "🎯 Models available: SeedVR2-3B and SeedVR2-7B"
echo "🌐 Ready to start Gradio interface on port 7860..."