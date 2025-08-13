# Base image
FROM python:3.10-slim

# Set environment variables
ENV DEBIAN_FRONTEND=noninteractive
ENV PYTHONUNBUFFERED=1
ENV PIP_NO_CACHE_DIR=1

# Install essential system dependencies (CUDA toolkit installed at runtime)
RUN apt-get update && apt-get install -y \
    git \
    wget \
    ffmpeg \
    build-essential \
    ninja-build \
    gnupg2 \
    curl \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

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
