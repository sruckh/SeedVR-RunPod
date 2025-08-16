# Base Image
FROM nvidia/cuda:12.6.3-cudnn-devel-ubuntu24.04

# Set working directory
WORKDIR /workspace

# Set DEBIAN_FRONTEND to noninteractive
ENV DEBIAN_FRONTEND=noninteractive

# Install basic dependencies
RUN apt-get update && apt-get install -y --no-install-recommends software-properties-common && \
    add-apt-repository -y ppa:deadsnakes/ppa && \
    apt-get update && \
    apt-get install -y --no-install-recommends \
    git \
    python3.10 \
    python3.10-venv \
    wget && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Create a python virtual environment
RUN python3.10 -m venv /workspace/venv

# Activate virtual environment
ENV PATH="/workspace/venv/bin:$PATH"

# Copy the run script and make it executable
COPY run.sh .
RUN chmod +x run.sh

# Command to run when the container starts
CMD ["./run.sh"]