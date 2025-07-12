# RunPod Deployment Guide

This guide walks you through deploying SeedVR on RunPod using the pre-built Docker container.

## 🚀 Quick Deployment

### Step 1: Create RunPod Account
1. Sign up at [RunPod.io](https://runpod.io)
2. Add credits to your account
3. Navigate to "Pods" section

### Step 2: Deploy Container
1. Click "Deploy" → "Custom Container"
2. **Container Configuration**:
   - **Container Image**: `gemneye/seedvr-runpod:latest`
   - **Port**: `7860`
   - **Volume**: Mount `/workspace` (recommended 100GB+)

3. **GPU Selection**:
   - **For SeedVR2-3B**: RTX 4090, A100-40GB, or better
   - **For SeedVR2-7B**: A100-80GB, H100, or better

4. **Environment Variables** (optional):
   ```
   GRADIO_SHARE=true
   HF_TOKEN=your_huggingface_token
   ```

### Step 3: Launch Pod
1. Click "Deploy Pod"
2. Wait for pod to start (status: Running)
3. Initial setup takes 10-15 minutes for model downloads

## 🔧 Configuration Options

### Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `GRADIO_SHARE` | `false` | Creates public Gradio link |
| `GRADIO_PORT` | `7860` | Port for web interface |
| `GRADIO_HOST` | `0.0.0.0` | Host binding |
| `HF_TOKEN` | - | Hugging Face token |

### GPU Recommendations

#### SeedVR2-3B (Faster, Good Quality)
- **Minimum**: 24GB VRAM
- **Recommended GPUs**:
  - RTX 4090 (24GB)
  - A100-40GB
  - A6000 (48GB)

#### SeedVR2-7B (Slower, Best Quality)
- **Minimum**: 40GB VRAM  
- **Recommended GPUs**:
  - A100-80GB
  - H100 (80GB)
  - Multiple A100-40GB with sequence parallelism

### Storage Requirements
- **Container**: ~10GB
- **Models**: ~25GB (3B + 7B models)
- **Processing**: 10-50GB (depends on video size)
- **Recommended**: 100GB+ persistent volume

## 📱 Accessing the Interface

### Via RunPod Dashboard
1. Go to your pod details
2. Click on port `7860` under "Exposed Ports"
3. Opens Gradio interface in new tab

### Via Public Link (if GRADIO_SHARE=true)
1. Check pod logs for public URL
2. Look for: "Public URL: https://xxx.gradio.live"
3. Share this link with others (temporary)

## 🎬 Using the Interface

### Model Selection
- **SeedVR2-3B**: Choose for faster processing
- **SeedVR2-7B**: Choose for highest quality

### Video Upload
- **Supported formats**: MP4, AVI, MOV
- **Recommended**: MP4 with H.264 encoding
- **Size limit**: Depends on available storage

### Settings
- **Output Resolution**: 512px to 2048px
- **Aspect Ratio**: Maintains input ratio by default
- **Seed**: Use same seed for reproducible results

### Processing
- **Progress Bar**: Shows current processing stage
- **Time Estimates**: Displayed during processing
- **Automatic Download**: Completed video downloads automatically

## 🛠️ Troubleshooting

### Common Issues

#### "No models found" Error
**Cause**: Models failed to download
**Solution**: 
1. Check internet connectivity
2. Restart pod
3. Check available storage space

#### Out of Memory Error
**Cause**: Insufficient GPU memory
**Solution**:
1. Use SeedVR2-3B instead of 7B
2. Reduce output resolution
3. Process shorter video clips

#### Long Processing Times
**Cause**: Video too long/high resolution
**Solution**:
1. Split long videos into shorter clips
2. Reduce output resolution
3. Use SeedVR2-3B for faster processing

#### Interface Not Loading
**Cause**: Port not accessible
**Solution**:
1. Check port 7860 is exposed
2. Wait for full container initialization
3. Check pod logs for errors

### Pod Logs
Monitor setup progress via pod logs:
```bash
# Key log messages to look for:
🚀 Setting up SeedVR environment...
📥 Downloading SeedVR2-3B...
📥 Downloading SeedVR2-7B...
✅ SeedVR environment setup complete!
🌐 Starting Gradio interface on port 7860...
```

## 💰 Cost Optimization

### GPU Selection
- **Development/Testing**: Use cheaper GPUs with SeedVR2-3B
- **Production**: Use faster GPUs to reduce processing time
- **Batch Processing**: Process multiple videos in one session

### Usage Patterns
- **On-Demand**: Start/stop pods as needed
- **Spot Instances**: Use spot pricing for non-urgent tasks
- **Persistent Storage**: Use persistent volumes for model caching

### Estimated Costs (RunPod pricing may vary)
- **RTX 4090**: ~$0.40/hour
- **A100-40GB**: ~$1.50/hour  
- **A100-80GB**: ~$2.50/hour
- **H100**: ~$4.00/hour

## 🔄 Updates and Maintenance

### Updating the Container
1. Stop current pod
2. Deploy new pod with updated image tag
3. Models are re-downloaded automatically

### Model Updates
Models are downloaded fresh each time. To force re-download:
1. Delete persistent volume
2. Restart pod

### Container Versions
- `latest`: Most recent stable version
- `v1.0.0`: Specific version tags
- `dev`: Development version (may be unstable)

## 📞 Support

### Getting Help
1. **Check Logs**: Always check pod logs first
2. **GitHub Issues**: Report bugs on GitHub
3. **RunPod Support**: For platform-specific issues
4. **Community**: Join discussions on GitHub

### Required Information for Support
- Pod configuration (GPU, RAM, storage)
- Environment variables used
- Error messages from logs
- Steps to reproduce the issue

---

**Happy video restoring! 🎬✨**