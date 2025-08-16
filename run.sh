#!/bin/bash
# SeedVR-RunPod: Simplified run script for PyTorch base image
# Eliminates complex dependency management and focuses on model setup

set -e

echo "--- SeedVR PyTorch Base Runtime ---"

# Environment validation
echo "Environment Info:"
python -c "import sys, torch; print(f'Python: {sys.version.split()[0]}'); print(f'PyTorch: {torch.__version__}'); print(f'CUDA: {torch.version.cuda}'); print(f'GPU Available: {torch.cuda.is_available()}')"

if python -c "import torch; exit(0 if torch.cuda.is_available() else 1)"; then
    python -c "import torch; print(f'GPU: {torch.cuda.get_device_name(0)}'); print(f'Compute capability: {torch.cuda.get_device_capability(0)}')"
else
    echo "⚠️ WARNING: CUDA not available"
fi

# Verify flash-attention
echo "Flash-attention status:"
python -c "import flash_attn; print(f'Flash-attention version: {flash_attn.__version__}')"

# Change to SeedVR directory
cd /workspace/SeedVR

# Download models if needed
echo "Downloading SeedVR models..."
python download.py

# Start the application
echo "Starting SeedVR application..."
exec python app.py