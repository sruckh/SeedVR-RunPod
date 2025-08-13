# Essential Development Commands

## Docker Operations
```bash
# Build the container locally
docker build -t seedvr-runpod:dev .

# Run with GPU support for testing
docker run --gpus all -p 7860:7860 -e GRADIO_SHARE=true seedvr-runpod:dev

# View container logs
docker logs -f <container_id>

# Access running container
docker exec -it <container_id> /bin/bash
```

## Git Operations
```bash
# Check repository status
git status

# Pull latest changes
git pull origin main

# Push changes
git push origin main

# Create and switch to feature branch
git checkout -b feature/branch-name

# View commit history
git log --oneline -10
```

## Local Development
```bash
# Make scripts executable
chmod +x run.sh

# Test download script
python download.py

# Test color fix utility
python color_fix.py

# Run Gradio app locally (after setup)
python app.py
```

## Testing and Validation
```bash
# Check Python syntax
python -m py_compile app.py
python -m py_compile download.py
python -m py_compile color_fix.py

# Validate shell script
bash -n run.sh

# Check Docker build without cache
docker build --no-cache -t seedvr-runpod:test .
```

## RunPod Deployment
```bash
# Pull from Docker Hub
docker pull gemneye/seedvr-runpod:latest

# Environment variables for RunPod
export GRADIO_SHARE=true
export HF_TOKEN=your_token_here
export GRADIO_PORT=7860
```

## File System Operations
```bash
# List project structure
find . -type f -name "*.py" -o -name "*.sh" -o -name "*.md" | head -20

# Check file permissions
ls -la *.sh

# Monitor disk usage during model downloads
df -h

# Watch GPU memory usage
nvidia-smi -l 1
```