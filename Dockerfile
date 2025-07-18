# SeedVR RunPod Container - Lightweight setup for remote installation
# Supports both SeedVR2-3B and SeedVR2-7B models
FROM python:3.10-slim

# Set environment variables
ENV DEBIAN_FRONTEND=noninteractive
ENV PYTHONUNBUFFERED=1
ENV PIP_NO_CACHE_DIR=1
ENV TORCH_HOME=/workspace/cache
ENV HF_HOME=/workspace/cache/huggingface
ENV CUDA_HOME=/usr/local/cuda
ENV PYTHONPATH="/workspace:$PYTHONPATH"

# Gradio configuration (can be overridden at runtime)
ENV GRADIO_SHARE=false
ENV GRADIO_PORT=7860
ENV GRADIO_HOST=0.0.0.0

# Install system dependencies
RUN apt-get update && apt-get install -y \
    git \
    wget \
    curl \
    build-essential \
    ffmpeg \
    libgl1-mesa-glx \
    libglib2.0-0 \
    libsm6 \
    libxext6 \
    libxrender-dev \
    libgomp1 \
    ninja-build \
    && rm -rf /var/lib/apt/lists/*

# Create workspace directory
WORKDIR /workspace

# Copy setup scripts and requirements
COPY requirements.txt setup_environment.sh download_models.py ./
COPY src/ ./src/
COPY gradio_app.py ./

# Install base PyTorch (CUDA 12.1 compatible)
RUN pip install --upgrade pip
RUN pip install torch==2.4.0 torchvision==0.19.0 torchaudio==2.4.0 --index-url https://download.pytorch.org/whl/cu121

# Install requirements (excluding torch packages already installed)
RUN pip install -r requirements.txt

# Install Gradio for the interface
RUN pip install gradio==4.44.0

# Make setup script executable
RUN chmod +x setup_environment.sh

# Create cache and model directories
RUN mkdir -p /workspace/cache/huggingface /workspace/ckpts /workspace/outputs /workspace/temp

# Download color fix utility during build
RUN wget -O /workspace/src/color_fix.py https://raw.githubusercontent.com/pkuliyi2015/sd-webui-stablesr/master/srmodule/colorfix.py

# Install flash-attention wheel and apex on first run (done in setup script)
# These are downloaded dynamically to match the exact CUDA environment

# Default command runs the setup and then the Gradio app
CMD ["bash", "-c", "/workspace/setup_environment.sh && export PYTHONPATH=/workspace:$PYTHONPATH && python gradio_app.py"]

# Expose Gradio port
EXPOSE 7860