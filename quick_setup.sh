#!/bin/bash

# Quick GitHub Repository Setup Script for SeedVR-RunPod
# Non-interactive version for users with SSH keys configured

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🚀 Quick Setup for SeedVR-RunPod GitHub Repository${NC}"

# Configuration - Update these values
GITHUB_USERNAME="sruckh"  # UPDATE THIS
REPO_NAME="SeedVR-RunPod"
DOCKERHUB_USERNAME="gemneye"  # UPDATE THIS

echo -e "${YELLOW}⚠️  Please update the usernames in this script before running!${NC}"
echo -e "Current config:"
echo -e "  GitHub: ${GITHUB_USERNAME}"
echo -e "  Docker Hub: ${DOCKERHUB_USERNAME}"
echo -e ""
read -p "Continue with these values? (y/N): " CONTINUE

if [[ ! $CONTINUE =~ ^[Yy]$ ]]; then
    echo -e "${YELLOW}Please edit quick_setup.sh and update the usernames first${NC}"
    exit 1
fi

# Check if we're in a git repository
if [ ! -d ".git" ]; then
    echo -e "${YELLOW}📁 Initializing Git repository...${NC}"
    git init
    git branch -m main
    echo -e "${GREEN}✅ Git repository initialized with main branch${NC}"
else
    echo -e "${GREEN}✅ Already in a Git repository${NC}"
fi

# Update files with usernames (create backups)
echo -e "${YELLOW}📝 Updating files with your usernames...${NC}"

# Function to update file if it exists
update_file() {
    local file=$1
    if [ -f "$file" ]; then
        cp "$file" "$file.bak"
        sed -i "s/yourusername/${DOCKERHUB_USERNAME}/g" "$file"
        if [[ "$file" == *"workflows"* ]] || [[ "$file" == *"CONTRIBUTING"* ]]; then
            sed -i "s/${DOCKERHUB_USERNAME}/${GITHUB_USERNAME}/g" "$file"
        fi
        echo -e "  ✅ Updated $file"
    fi
}

# Update documentation files
update_file "README.md"
update_file "RUNPOD_DEPLOYMENT.md"
update_file "CONTRIBUTING.md"
update_file ".github/workflows/docker-build-push.yml"
update_file "scripts/build_and_push.sh"

echo -e "${GREEN}✅ Files updated with your usernames${NC}"

# Add .gitignore additions
echo -e "${YELLOW}📝 Updating .gitignore...${NC}"
cat >> .gitignore << 'EOF'

# Local data directories
data/
cache/
ckpts/
outputs/
temp/

# Environment files
.env

# Backup files
*.bak
EOF
echo -e "${GREEN}✅ .gitignore updated${NC}"

# Add all files to git
echo -e "${YELLOW}📦 Adding files to Git...${NC}"
git add .
echo -e "${GREEN}✅ Files staged for commit${NC}"

# Create initial commit
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

echo -e "\n${BLUE}🌐 Next Steps for GitHub Repository${NC}"
echo -e "\n${YELLOW}1. Create the repository on GitHub:${NC}"
echo -e "   Go to: https://github.com/new"
echo -e "   Repository name: ${REPO_NAME}"
echo -e "   Description: 🎬 SeedVR RunPod Container - Lightweight Docker container for SeedVR video restoration"
echo -e "   Choose public or private"
echo -e "   Do NOT initialize with README (we have one)"

echo -e "\n${YELLOW}2. Connect and push to GitHub:${NC}"
echo -e "   git remote add origin git@github.com:${GITHUB_USERNAME}/${REPO_NAME}.git"
echo -e "   git push -u origin main"

echo -e "\n${YELLOW}3. Set up GitHub Secrets for Docker Hub deployment:${NC}"
echo -e "   ${GREEN}Note: The GitHub Actions are configured to be safe without secrets!${NC}"
echo -e "   The workflow will build but not push until secrets are configured."
echo -e ""
echo -e "   Go to: https://github.com/${GITHUB_USERNAME}/${REPO_NAME}/settings/secrets/actions"
echo -e "   Add secret: DOCKERHUB_USERNAME = ${DOCKERHUB_USERNAME}"
echo -e "   Add secret: DOCKERHUB_TOKEN = [Your Docker Hub access token]"

echo -e "\n${YELLOW}4. Create Docker Hub access token:${NC}"
echo -e "   Go to: https://hub.docker.com/settings/security"
echo -e "   Create new token: 'GitHub Actions SeedVR'"
echo -e "   Permissions: Read, Write, Delete"

echo -e "\n${YELLOW}5. Enable automatic builds (after secrets are set):${NC}"
echo -e "   Edit .github/workflows/docker-build-push.yml"
echo -e "   Uncomment the push/pull_request triggers"
echo -e "   Or manually trigger builds from the Actions tab"

echo -e "\n${BLUE}🧪 Test locally:${NC}"
echo -e "   export HF_TOKEN=your_huggingface_token"
echo -e "   ./scripts/test_local.sh"

echo -e "\n${GREEN}🎉 Repository setup completed!${NC}"
echo -e "Files are ready to push to GitHub. Follow the steps above to complete the setup."

# Show the commands to run
echo -e "\n${BLUE}📋 Commands to run next:${NC}"
echo -e "${GREEN}git remote add origin git@github.com:${GITHUB_USERNAME}/${REPO_NAME}.git${NC}"
echo -e "${GREEN}git push -u origin main${NC}"
