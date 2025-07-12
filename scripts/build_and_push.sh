#!/bin/bash

# Build and Push Script for SeedVR-RunPod
# Usage: ./scripts/build_and_push.sh [tag]

set -e

# Configuration
DOCKER_USERNAME=${DOCKERHUB_USERNAME:-"gemneye"}
IMAGE_NAME="seedvr-runpod"
TAG=${1:-"latest"}
PLATFORMS="linux/amd64"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🚀 Building and pushing SeedVR-RunPod container${NC}"
echo -e "${BLUE}Repository: ${DOCKER_USERNAME}/${IMAGE_NAME}:${TAG}${NC}"

# Check if docker buildx is available
if ! docker buildx version > /dev/null 2>&1; then
    echo -e "${RED}❌ Docker buildx is required for multi-platform builds${NC}"
    exit 1
fi

# Check if logged in to Docker Hub
if ! docker info | grep -q "Username"; then
    echo -e "${YELLOW}⚠️  Not logged in to Docker Hub. Please run 'docker login'${NC}"
    exit 1
fi

# Create buildx builder if it doesn't exist
BUILDER_NAME="seedvr-builder"
if ! docker buildx ls | grep -q "$BUILDER_NAME"; then
    echo -e "${YELLOW}📦 Creating buildx builder: $BUILDER_NAME${NC}"
    docker buildx create --name "$BUILDER_NAME" --driver docker-container --bootstrap
fi

# Use the builder
docker buildx use "$BUILDER_NAME"

# Build and push
echo -e "${GREEN}🔨 Building for platforms: ${PLATFORMS}${NC}"
docker buildx build \
    --platform "$PLATFORMS" \
    --tag "${DOCKER_USERNAME}/${IMAGE_NAME}:${TAG}" \
    --tag "${DOCKER_USERNAME}/${IMAGE_NAME}:latest" \
    --push \
    --progress=plain \
    .

echo -e "${GREEN}✅ Successfully built and pushed ${DOCKER_USERNAME}/${IMAGE_NAME}:${TAG}${NC}"
echo -e "${GREEN}✅ Also tagged as: ${DOCKER_USERNAME}/${IMAGE_NAME}:latest${NC}"

# Test the pushed image
echo -e "${BLUE}🧪 Testing the pushed image...${NC}"
docker run --rm "${DOCKER_USERNAME}/${IMAGE_NAME}:${TAG}" python --version

echo -e "${GREEN}🎉 Build and push completed successfully!${NC}"
echo -e "${BLUE}Run with: docker run --gpus all -p 7860:7860 -e HF_TOKEN=your_token ${DOCKER_USERNAME}/${IMAGE_NAME}:${TAG}${NC}"