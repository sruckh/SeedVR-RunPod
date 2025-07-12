#!/bin/bash

# Local Testing Script for SeedVR-RunPod
# Usage: ./scripts/test_local.sh

set -e

# Configuration
IMAGE_NAME="seedvr-runpod:test"
CONTAINER_NAME="seedvr-test"
TEST_PORT=7860

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🧪 Testing SeedVR-RunPod locally${NC}"

# Check if HF_TOKEN is set
if [ -z "$HF_TOKEN" ]; then
    echo -e "${RED}❌ HF_TOKEN environment variable is required${NC}"
    echo -e "${YELLOW}Please set your Hugging Face token: export HF_TOKEN=your_token${NC}"
    exit 1
fi

# Check if GPU is available
if ! nvidia-smi > /dev/null 2>&1; then
    echo -e "${YELLOW}⚠️  nvidia-smi not found. GPU testing will be limited.${NC}"
    GPU_FLAG=""
else
    echo -e "${GREEN}✅ GPU detected${NC}"
    GPU_FLAG="--gpus all"
fi

# Clean up any existing test container
echo -e "${YELLOW}🧹 Cleaning up existing test containers...${NC}"
docker stop "$CONTAINER_NAME" 2>/dev/null || true
docker rm "$CONTAINER_NAME" 2>/dev/null || true

# Build the image
echo -e "${BLUE}🔨 Building test image...${NC}"
docker build -t "$IMAGE_NAME" .

# Run the container
echo -e "${BLUE}🚀 Starting test container...${NC}"
docker run -d \
    --name "$CONTAINER_NAME" \
    $GPU_FLAG \
    -p "$TEST_PORT:7860" \
    -e HF_TOKEN="$HF_TOKEN" \
    -e GRADIO_SHARE=false \
    "$IMAGE_NAME"

# Function to cleanup on exit
cleanup() {
    echo -e "\n${YELLOW}🧹 Cleaning up...${NC}"
    docker stop "$CONTAINER_NAME" 2>/dev/null || true
    docker rm "$CONTAINER_NAME" 2>/dev/null || true
}
trap cleanup EXIT

# Wait for container to start
echo -e "${BLUE}⏳ Waiting for container to start...${NC}"
sleep 10

# Check if container is running
if ! docker ps | grep -q "$CONTAINER_NAME"; then
    echo -e "${RED}❌ Container failed to start${NC}"
    echo -e "${YELLOW}📋 Container logs:${NC}"
    docker logs "$CONTAINER_NAME"
    exit 1
fi

echo -e "${GREEN}✅ Container is running${NC}"

# Show logs
echo -e "${BLUE}📋 Container logs (last 20 lines):${NC}"
docker logs --tail 20 "$CONTAINER_NAME"

# Test if Gradio is accessible
echo -e "${BLUE}🌐 Testing Gradio interface...${NC}"
for i in {1..30}; do
    if curl -s "http://localhost:$TEST_PORT" > /dev/null; then
        echo -e "${GREEN}✅ Gradio interface is accessible at http://localhost:$TEST_PORT${NC}"
        break
    fi
    if [ $i -eq 30 ]; then
        echo -e "${RED}❌ Gradio interface not accessible after 5 minutes${NC}"
        echo -e "${YELLOW}📋 Recent logs:${NC}"
        docker logs --tail 50 "$CONTAINER_NAME"
        exit 1
    fi
    echo -e "${YELLOW}⏳ Waiting for Gradio to start... (${i}/30)${NC}"
    sleep 10
done

# Run basic tests inside container
echo -e "${BLUE}🔧 Running internal tests...${NC}"

# Test Python environment
docker exec "$CONTAINER_NAME" python -c "
import sys
print(f'Python version: {sys.version}')
print('✅ Python environment OK')
"

# Test PyTorch
docker exec "$CONTAINER_NAME" python -c "
import torch
print(f'PyTorch version: {torch.__version__}')
print(f'CUDA available: {torch.cuda.is_available()}')
if torch.cuda.is_available():
    print(f'CUDA version: {torch.version.cuda}')
    print(f'GPU count: {torch.cuda.device_count()}')
print('✅ PyTorch environment OK')
"

# Test imports
docker exec "$CONTAINER_NAME" python -c "
try:
    import gradio
    print(f'Gradio version: {gradio.__version__}')
    print('✅ Gradio import OK')
except Exception as e:
    print(f'❌ Gradio import failed: {e}')
    exit(1)

try:
    import huggingface_hub
    print(f'HuggingFace Hub available')
    print('✅ HuggingFace Hub OK')
except Exception as e:
    print(f'❌ HuggingFace Hub failed: {e}')
    exit(1)
"

# Check if models are being downloaded
echo -e "${BLUE}📥 Checking model download status...${NC}"
docker exec "$CONTAINER_NAME" ls -la /workspace/ckpts/ 2>/dev/null || echo "Models directory not ready yet"

echo -e "${GREEN}🎉 Local testing completed successfully!${NC}"
echo -e "${BLUE}📝 Summary:${NC}"
echo -e "  • Container: $CONTAINER_NAME"
echo -e "  • Image: $IMAGE_NAME"
echo -e "  • Port: http://localhost:$TEST_PORT"
echo -e "  • Status: Running"
echo -e "\n${YELLOW}To view logs: docker logs -f $CONTAINER_NAME${NC}"
echo -e "${YELLOW}To stop: docker stop $CONTAINER_NAME${NC}"

# Keep container running if requested
if [ "$1" = "--keep-running" ]; then
    echo -e "${BLUE}🔄 Container will keep running (use Ctrl+C to stop and cleanup)${NC}"
    trap 'cleanup' INT
    while true; do
        sleep 10
    done
fi