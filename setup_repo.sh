#!/bin/bash

# GitHub Repository Setup Script for SeedVR-RunPod
# This script helps set up the GitHub repository with all necessary configurations

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🚀 Setting up SeedVR-RunPod GitHub Repository${NC}"

# Check if we're in a git repository
if [ ! -d ".git" ]; then
    echo -e "${YELLOW}📁 Initializing Git repository...${NC}"
    git init
    echo -e "${GREEN}✅ Git repository initialized${NC}"
else
    echo -e "${GREEN}✅ Already in a Git repository${NC}"
fi

# Check if gh CLI is available
if command -v gh &> /dev/null; then
    echo -e "${GREEN}✅ GitHub CLI (gh) is available${NC}"
    GH_AVAILABLE=true
else
    echo -e "${YELLOW}⚠️  GitHub CLI (gh) not found. You'll need to create the repository manually.${NC}"
    GH_AVAILABLE=false
fi

# Get repository information
echo -e "\n${BLUE}📝 Repository Configuration${NC}"
read -p "Enter your GitHub username: " GITHUB_USERNAME
read -p "Enter repository name [seedvr-runpod]: " REPO_NAME
REPO_NAME=${REPO_NAME:-seedvr-runpod}
read -p "Enter your Docker Hub username: " DOCKERHUB_USERNAME

# Validate inputs
if [ -z "$GITHUB_USERNAME" ] || [ -z "$DOCKERHUB_USERNAME" ]; then
    echo -e "${RED}❌ GitHub username and Docker Hub username are required${NC}"
    exit 1
fi

echo -e "\n${BLUE}🔧 Configuration Summary:${NC}"
echo -e "  GitHub: https://github.com/${GITHUB_USERNAME}/${REPO_NAME}"
echo -e "  Docker Hub: ${DOCKERHUB_USERNAME}/seedvr-runpod"
echo ""

# Update README with correct usernames
echo -e "${YELLOW}📝 Updating README with your usernames...${NC}"
sed -i.bak "s/yourusername/${DOCKERHUB_USERNAME}/g" README.md
sed -i.bak "s/yourusername/${GITHUB_USERNAME}/g" RUNPOD_DEPLOYMENT.md
sed -i.bak "s/yourusername/${DOCKERHUB_USERNAME}/g" CONTRIBUTING.md
sed -i.bak "s/yourusername/${GITHUB_USERNAME}/g" .github/workflows/docker-build-push.yml
rm -f README.md.bak RUNPOD_DEPLOYMENT.md.bak CONTRIBUTING.md.bak .github/workflows/docker-build-push.yml.bak

# Update build script
sed -i.bak "s/yourusername/${DOCKERHUB_USERNAME}/g" scripts/build_and_push.sh
rm -f scripts/build_and_push.sh.bak

echo -e "${GREEN}✅ Documentation updated with your usernames${NC}"

# Create .gitignore if it doesn't exist or is incomplete
echo -e "${YELLOW}📝 Setting up .gitignore...${NC}"
cat >> .gitignore << 'EOF'

# Local data directories
data/
cache/
ckpts/
outputs/
temp/

# Environment files
.env

# VS Code
.vscode/

# IDE files
.idea/

# macOS
.DS_Store

# Backup files
*.bak
*~
EOF
echo -e "${GREEN}✅ .gitignore configured${NC}"

# Add all files to git
echo -e "${YELLOW}📦 Adding files to Git...${NC}"
git add .
echo -e "${GREEN}✅ Files added to Git${NC}"

# Initial commit
if [ -z "$(git log --oneline 2>/dev/null)" ]; then
    echo -e "${YELLOW}📝 Creating initial commit...${NC}"
    git commit -m "Initial commit: SeedVR RunPod container

- Lightweight Docker container for SeedVR deployment
- Supports SeedVR2-3B and SeedVR2-7B models
- Gradio web interface with model selection
- Robust setup with retry logic and error handling
- Smart caching for wheels and models
- Comprehensive GPU and CUDA verification
- GitHub Actions for automated Docker Hub deployment

🤖 Generated with [Claude Code](https://claude.ai/code)

Co-Authored-By: Claude <noreply@anthropic.com>"
    echo -e "${GREEN}✅ Initial commit created${NC}"
else
    echo -e "${GREEN}✅ Repository already has commits${NC}"
fi

# Create GitHub repository if gh CLI is available
if [ "$GH_AVAILABLE" = true ]; then
    echo -e "\n${BLUE}🌐 Creating GitHub Repository${NC}"
    read -p "Create public repository? (y/N): " CREATE_PUBLIC
    
    if [[ $CREATE_PUBLIC =~ ^[Yy]$ ]]; then
        VISIBILITY="--public"
        echo -e "${YELLOW}📢 Creating public repository...${NC}"
    else
        VISIBILITY="--private"
        echo -e "${YELLOW}🔒 Creating private repository...${NC}"
    fi
    
    # Create repository description
    DESCRIPTION="🎬 SeedVR RunPod Container - Lightweight Docker container for deploying SeedVR video restoration models on RunPod with Gradio interface"
    
    if gh repo create "$GITHUB_USERNAME/$REPO_NAME" $VISIBILITY --description "$DESCRIPTION" --source=. --push; then
        echo -e "${GREEN}✅ GitHub repository created and pushed${NC}"
        REPO_URL="https://github.com/${GITHUB_USERNAME}/${REPO_NAME}"
        echo -e "${GREEN}🌐 Repository URL: $REPO_URL${NC}"
    else
        echo -e "${RED}❌ Failed to create GitHub repository${NC}"
        echo -e "${YELLOW}You can create it manually at: https://github.com/new${NC}"
    fi
else
    echo -e "\n${YELLOW}📝 Manual Setup Instructions:${NC}"
    echo -e "1. Go to https://github.com/new"
    echo -e "2. Repository name: $REPO_NAME"
    echo -e "3. Add description: SeedVR RunPod Container - Lightweight Docker container for SeedVR video restoration"
    echo -e "4. Choose public or private"
    echo -e "5. Don't initialize with README (we already have one)"
    echo -e "6. Create repository"
    echo -e "7. Run these commands:"
    echo -e "   git remote add origin https://github.com/${GITHUB_USERNAME}/${REPO_NAME}.git"
    echo -e "   git branch -M main"
    echo -e "   git push -u origin main"
fi

# GitHub Secrets setup instructions
echo -e "\n${BLUE}🔐 GitHub Secrets Setup${NC}"
echo -e "To enable automatic Docker Hub deployment, add these secrets to your GitHub repository:"
echo -e "\n${YELLOW}Repository Settings → Secrets and variables → Actions → New repository secret:${NC}"
echo -e "1. Name: ${GREEN}DOCKERHUB_USERNAME${NC}, Value: ${GREEN}${DOCKERHUB_USERNAME}${NC}"
echo -e "2. Name: ${GREEN}DOCKERHUB_TOKEN${NC}, Value: ${GREEN}[Your Docker Hub Access Token]${NC}"
echo -e "\n${YELLOW}💡 To create a Docker Hub access token:${NC}"
echo -e "1. Go to https://hub.docker.com/settings/security"
echo -e "2. Click 'New Access Token'"
echo -e "3. Name: 'GitHub Actions SeedVR'"
echo -e "4. Permissions: 'Read, Write, Delete'"
echo -e "5. Copy the token and add it as DOCKERHUB_TOKEN secret"

# Local testing instructions
echo -e "\n${BLUE}🧪 Local Testing${NC}"
echo -e "Test your container locally:"
echo -e "1. ${GREEN}export HF_TOKEN=your_huggingface_token${NC}"
echo -e "2. ${GREEN}./scripts/test_local.sh${NC}"
echo -e "\nBuild and push manually:"
echo -e "1. ${GREEN}docker login${NC}"
echo -e "2. ${GREEN}./scripts/build_and_push.sh v1.0.0${NC}"

# Final summary
echo -e "\n${GREEN}🎉 Repository setup completed!${NC}"
echo -e "\n${BLUE}📋 Next Steps:${NC}"
echo -e "✅ Git repository initialized"
echo -e "✅ Files committed to Git"
if [ "$GH_AVAILABLE" = true ] && [[ $CREATE_PUBLIC =~ ^[Yy]$ || $CREATE_PUBLIC =~ ^[Nn]$ ]]; then
    echo -e "✅ GitHub repository created"
else
    echo -e "⏳ Create GitHub repository manually"
fi
echo -e "⏳ Add Docker Hub secrets to GitHub"
echo -e "⏳ Test locally with your HF_TOKEN"
echo -e "⏳ Push to trigger first Docker build"

echo -e "\n${YELLOW}🔗 Important Links:${NC}"
echo -e "📁 Repository: https://github.com/${GITHUB_USERNAME}/${REPO_NAME}"
echo -e "🐳 Docker Hub: https://hub.docker.com/r/${DOCKERHUB_USERNAME}/seedvr-runpod"
echo -e "📖 RunPod Guide: https://github.com/${GITHUB_USERNAME}/${REPO_NAME}/blob/main/RUNPOD_DEPLOYMENT.md"

echo -e "\n${GREEN}Happy containerizing! 🚀${NC}"