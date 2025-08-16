# SeedVR-RunPod: PyTorch Base Image Approach
# Addresses L40 GPU compatibility and reduces complexity from 60+ commits

FROM pytorch/pytorch:2.7.1-cuda12.6-cudnn9-devel

# Set working directory
WORKDIR /workspace

# Install system dependencies
RUN apt-get update && apt-get install -y \
    git \
    wget \
    ffmpeg \
    && rm -rf /var/lib/apt/lists/*

# Install flash-attention using ByteDance wheel (proven L40 compatibility)
# Using v2.5.8 from SeedVR team - tested with their models and L40 GPU
RUN pip install --no-cache-dir --force-reinstall --no-deps \
    https://huggingface.co/ByteDance-Seed/SeedVR2-3B/resolve/main/flash_attn-2.5.8+cu121torch2.3cxx11abiFALSE-cp310-cp310-linux_x86_64.whl

# Clone SeedVR repository
RUN git clone https://github.com/ByteDance-Seed/SeedVR.git /workspace/SeedVR
WORKDIR /workspace/SeedVR

# Print environment info for debugging
RUN python -c "import sys, torch; print(f'Python: {sys.version.split()[0]}'); print(f'PyTorch: {torch.__version__}'); print(f'CUDA: {torch.version.cuda}'); print(f'GPU Available: {torch.cuda.is_available()}')"

# Install minimal SeedVR dependencies (carefully avoiding PyTorch conflicts)
RUN pip install --no-cache-dir \
    transformers \
    diffusers \
    accelerate \
    xformers \
    av \
    pillow \
    opencv-python \
    numpy \
    scipy \
    tqdm \
    gradio

# Copy our optimized files
COPY download.py /workspace/SeedVR/
COPY app.py /workspace/SeedVR/

# Verify flash-attention installation
RUN python -c "import flash_attn; print(f'Flash-attention version: {flash_attn.__version__}')"

# Set environment variables
ENV PYTHONPATH="/workspace/SeedVR:$PYTHONPATH"
ENV GRADIO_SHARE=0

# Expose port
EXPOSE 7860

# Run the application
CMD ["python", "app.py"]