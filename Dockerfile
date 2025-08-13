# Base image
FROM python:3.10-slim

# Set environment variables
ENV DEBIAN_FRONTEND=noninteractive
ENV PYTHONUNBUFFERED=1
ENV PIP_NO_CACHE_DIR=1

# Install essential system dependencies and CUDA toolkit for Apex
RUN apt-get update && apt-get install -y \
    git \
    wget \
    ffmpeg \
    build-essential \
    ninja-build \
    gnupg2 \
    curl \
    ca-certificates \
    && wget https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2004/x86_64/cuda-keyring_1.0-1_all.deb \
    && dpkg -i cuda-keyring_1.0-1_all.deb \
    && apt-get update \
    && apt-get install -y cuda-toolkit-12-1 \
    && rm -rf /var/lib/apt/lists/* \
    && rm cuda-keyring_1.0-1_all.deb

# Set CUDA environment variables
ENV CUDA_HOME=/usr/local/cuda
ENV PATH=${CUDA_HOME}/bin:${PATH}
ENV LD_LIBRARY_PATH=${CUDA_HOME}/lib64:${LD_LIBRARY_PATH}

# Set the working directory
WORKDIR /workspace

# Copy all necessary scripts and make run.sh executable
COPY run.sh .
COPY download.py .
COPY app.py .
COPY color_fix.py .
RUN chmod +x run.sh

# Set the entrypoint for the container
CMD ["./run.sh"]
