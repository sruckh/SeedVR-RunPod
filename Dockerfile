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

# Install flash-attention from PyPI (compatible with PyTorch base image)
# PyPI version handles platform compatibility automatically
RUN pip install --no-cache-dir flash-attn

# Clone SeedVR repository
RUN git clone https://github.com/ByteDance-Seed/SeedVR.git /workspace/SeedVR
WORKDIR /workspace/SeedVR

# Print environment info for debugging
RUN python -c "import sys, torch; print(f'Python: {sys.version.split()[0]}'); print(f'PyTorch: {torch.__version__}'); print(f'CUDA: {torch.version.cuda}'); print(f'GPU Available: {torch.cuda.is_available()}')"

# Install SeedVR dependencies individually to avoid conflicts
RUN pip install --no-cache-dir transformers && \
    pip install --no-cache-dir diffusers && \
    pip install --no-cache-dir accelerate && \
    pip install --no-cache-dir xformers && \
    pip install --no-cache-dir av && \
    pip install --no-cache-dir pillow && \
    pip install --no-cache-dir opencv-python && \
    pip install --no-cache-dir numpy && \
    pip install --no-cache-dir scipy && \
    pip install --no-cache-dir tqdm && \
    pip install --no-cache-dir gradio

# Copy our optimized files
COPY download.py /workspace/SeedVR/
COPY app.py /workspace/SeedVR/

# Verify flash-attention installation
RUN python -c "import flash_attn; print(f'Flash-attention version: {flash_attn.__version__}')"

# Set environment variables
ENV PYTHONPATH="/workspace/SeedVR"
ENV GRADIO_SHARE=0

# Expose port
EXPOSE 7860

# Run the application
CMD ["python", "app.py"]