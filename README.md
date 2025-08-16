# SeedVR RunPod Container

A lightweight Docker container for deploying SeedVR video restoration models on RunPod. Supports both **SeedVR2-3B** and **SeedVR2-7B** models with a user-friendly Gradio interface.

> **🚀 Recent Update**: Now uses PyTorch 2.7.1 + CUDA 12.6 base image for improved L40 GPU compatibility and reduced complexity. See `README_pytorch_approach.md` for technical details.

## 🚀 Features

- **Dual Model Support**: Choose between SeedVR2-3B (faster) or SeedVR2-7B (higher quality)
- **Lightweight Container**: Downloads models and dependencies on the remote host
- **Gradio Interface**: Easy-to-use web interface for video restoration
- **RunPod Optimized**: Designed specifically for RunPod deployment
- **GPU Accelerated**: Supports multi-GPU inference with sequence parallelism
- **Robust Setup**: Enhanced error checking, retry logic, and CUDA verification
- **Smart Caching**: Caches wheels and models to speed up restarts
- **Comprehensive Monitoring**: Real-time GPU verification and tensor operation testing

## 📋 Requirements

### Hardware
- **GPU**: NVIDIA GPU with at least 24GB VRAM (for SeedVR2-3B)
- **GPU**: NVIDIA GPU with at least 40GB VRAM (for SeedVR2-7B)
- **Storage**: At least 50GB free space for models and processing
- **CUDA**: Compatible with CUDA 12.1+

### Software
- Docker with NVIDIA GPU support
- NVIDIA Docker runtime
- **Python 3.10** (PyTorch base image)
- **PyTorch 2.7.1** with **CUDA 12.6** support (PyTorch official base)
- **Flash-attention 2.8.3** for L40 GPU compatibility
- **Minimal dependencies** - selective installation vs full requirements.txt

## 🐳 Docker Hub

The pre-built image is available on Docker Hub:
```bash
docker pull gemneye/seedvr-runpod:latest
```

## 🔧 Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `GRADIO_SHARE` | `false` | Enable Gradio sharing (true/false) |
| `GRADIO_PORT` | `7860` | Port for Gradio interface |
| `GRADIO_HOST` | `0.0.0.0` | Host binding for Gradio |
| `HF_TOKEN` | - | Hugging Face token (if needed) |

## 🚀 Quick Start

### RunPod Deployment

1. **Create a new RunPod instance**:
   - Choose a GPU pod with sufficient VRAM
   - Use the custom container option
   - Container image: `gemneye/seedvr-runpod:latest`
   - Expose port: `7860`

2. **Set environment variables** (optional):
   ```bash
   GRADIO_SHARE=true
   HF_TOKEN=your_token_here
   ```

3. **Start the container**:
   The container will automatically:
   - Download required models (SeedVR2-3B and SeedVR2-7B)
   - Install flash-attention and apex
   - Launch the Gradio interface on port 7860

4. **Access the interface**:
   - Open the provided URL in your browser
   - Upload a video and select your preferred model
   - Adjust output resolution and settings
   - Click "Restore Video" to process

### Local Development

```bash
# Clone the repository
git clone https://github.com/gemneye/SeedVR-RunPod.git
cd SeedVR-RunPod

# Build the Docker image
docker build -t seedvr-runpod .

# Run with GPU support
docker run --gpus all -p 7860:7860 -e GRADIO_SHARE=true seedvr-runpod
```

## 📝 Usage Guide

### Model Selection
- **SeedVR2-3B**: Faster processing, good quality, requires ~24GB VRAM
- **SeedVR2-7B**: Higher quality, slower processing, requires ~40GB VRAM

### Input Recommendations
- **Format**: MP4 videos work best
- **Length**: Shorter videos (< 30 seconds) process faster
- **Resolution**: Input resolution affects processing time
- **Quality**: Best results on videos with compression artifacts or low quality

### Output Settings
- **Width/Height**: Adjust output resolution (512-2048px)
- **Seed**: Fixed seed for reproducible results
- **Processing Time**: Varies based on video length and resolution

## 🛡️ Enhanced Robustness

Based on proven patterns from production deployments, this container includes:

### CUDA & GPU Verification
- **Real Tensor Operations**: Tests actual GPU computations, not just availability
- **Memory Detection**: Reports GPU memory and capabilities
- **Environment Setup**: Configures RANK, LOCAL_RANK, WORLD_SIZE for proper inference
- **Comprehensive Logging**: Detailed status reporting throughout setup

### Retry Logic & Error Handling
- **Exponential Backoff**: Smart retry timing for downloads and installations  
- **Wheel Caching**: Pre-downloads and caches flash_attn and apex wheels
- **Resume Downloads**: Models resume from interruption points
- **Graceful Degradation**: Continues setup even if optional components fail

### Installation Verification
- **Dependency Checking**: Verifies each component before proceeding
- **Version Validation**: Ensures compatible PyTorch/CUDA versions
- **Setup Completion**: Marks successful setup to avoid re-running
- **Storage Monitoring**: Reports available space during downloads

### Version Management
- **Fixed Dependencies**: Uses tested, compatible package versions
- **CUDA Compatibility**: PyTorch 2.4.0 + CUDA 12.1 for optimal performance
- **Dependabot**: Configured for security patches only (no major version bumps)
- **Environment Stability**: Python 3.10 ensures compatibility with all components

## 🔧 Manual Setup

If you need to set up the environment manually:

```bash
# Install flash-attention (with retry logic)
pip install https://github.com/Dao-AILab/flash-attention/releases/download/v2.5.9.post1/flash_attn-2.5.9.post1+cu122torch2.4cxx11abiFALSE-cp310-cp310-linux_x86_64.whl

# Install apex (with caching)
pip install https://huggingface.co/ByteDance-Seed/SeedVR2-3B/resolve/main/apex-0.1-cp310-cp310-linux_x86_64.whl

# Download models (with resume capability)
python download_models.py --model both
```

## 📊 Performance Notes

### GPU Memory Requirements
- **SeedVR2-3B**: ~24GB VRAM for 720p videos
- **SeedVR2-7B**: ~40GB VRAM for 720p videos
- **Multi-GPU**: Sequence parallelism reduces per-GPU memory usage

### Processing Times (Approximate)
- **10-second 720p video**: 2-5 minutes (3B), 5-10 minutes (7B)
- **30-second 1080p video**: 10-15 minutes (3B), 20-30 minutes (7B)

## 🛠️ Development

### Building the Image
```bash
docker build -t seedvr-runpod:dev .
```

### GitHub Actions
The repository includes automated building and pushing to Docker Hub:
- Triggers on push to main/develop branches
- Creates tagged releases
- Supports manual workflow dispatch

### Required Secrets
Set these in your GitHub repository:
- `DOCKERHUB_USERNAME`: Your Docker Hub username
- `DOCKERHUB_TOKEN`: Your Docker Hub access token

## 📄 License

This project follows the original SeedVR licensing:
- **SeedVR**: Apache 2.0 License
- **Container Code**: MIT License

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## 📞 Support

- **Issues**: Report bugs via GitHub Issues
- **Discussions**: Use GitHub Discussions for questions
- **Original SeedVR**: Visit the [original repository](https://github.com/bytedance-seed/SeedVR)

## 🙏 Acknowledgments

- **ByteDance**: For the original SeedVR models and research
- **RunPod**: For the cloud GPU platform
- **Gradio**: For the web interface framework

---

**Note**: This is an unofficial containerization of SeedVR for RunPod deployment. Please refer to the original [SeedVR repository](https://github.com/bytedance-seed/SeedVR) for the latest model updates and research.