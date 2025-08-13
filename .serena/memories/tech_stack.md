# Tech Stack and Dependencies

## Core Technologies
- **Python**: 3.10 (fixed version for compatibility)
- **PyTorch**: 2.4.0 with CUDA 12.1 support
- **CUDA**: 12.1+ for GPU acceleration
- **Docker**: Containerization with NVIDIA GPU support
- **Gradio**: Web interface framework

## Key Dependencies
- **flash-attention**: 2.5.9.post1 (GPU acceleration)
- **NVIDIA Apex**: Performance optimizations
- **huggingface_hub**: Model downloading
- **FFmpeg**: Video processing
- **PIL/Pillow**: Image processing

## Infrastructure
- **Base Image**: python:3.10-slim
- **Build System**: Docker with multi-stage builds
- **CI/CD**: GitHub Actions for automated Docker Hub pushes
- **Deployment**: RunPod cloud GPU platform
- **Storage**: Temporary directories for video processing

## GPU Requirements
- NVIDIA GPU with CUDA support
- 24GB+ VRAM for SeedVR2-3B model
- 40GB+ VRAM for SeedVR2-7B model
- Multi-GPU support with sequence parallelism