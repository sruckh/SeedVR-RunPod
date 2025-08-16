# Base Image
FROM nvidia/cuda:12.6.3-cudnn-devel-ubuntu24.04

# Set working directory
WORKDIR /workspace

# Set DEBIAN_FRONTEND to noninteractive
ENV DEBIAN_FRONTEND=noninteractive

# Install basic dependencies
RUN apt-get update && apt-get install -y \
    git \
    python3.11 \
    python3.11-venv \
    wget \
    --no-install-recommends && \
    rm -rf /var/lib/apt/lists/*

# Create a python virtual environment
RUN python3.11 -m venv /workspace/venv

# Activate virtual environment
ENV PATH="/workspace/venv/bin:$PATH"

# Copy the run script and make it executable
COPY run.sh .
RUN chmod +x run.sh

# Command to run when the container starts
CMD ["./run.sh"]