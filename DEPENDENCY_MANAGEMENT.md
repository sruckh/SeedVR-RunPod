# 📦 Dependency Management Guide

## ⚠️ **Important: Current Dependabot PRs**

The repository currently has several Dependabot PRs that **should be carefully reviewed** before merging. Many of these contain **major version bumps** that could break the carefully configured SeedVR environment.

### 🚫 **PRs to Close Without Merging:**

These PRs contain incompatible changes:

1. **Python Version Updates**:
   - `dependabot/docker/python-3.13-slim` - ❌ **Close** (Python 3.10 required)

2. **Major Version Bumps** (potentially breaking):
   - `dependabot/pip/transformers-4.53.2` - ⚠️ **Review** (SeedVR tested with 4.38.2)
   - `dependabot/pip/accelerate-1.8.1` - ⚠️ **Review** (tested with 0.33.0)
   - `dependabot/pip/huggingface-hub-0.33.4` - ⚠️ **Review** (tested with 0.32.2)
   - `dependabot/pip/pillow-11.3.0` - ⚠️ **Review** (tested with 10.3.0)
   - `dependabot/pip/opencv-python-4.12.0.88` - ⚠️ **Review** (tested with 4.9.0.80)

3. **Minor/Patch Updates** (likely safe):
   - `dependabot/pip/tqdm-4.67.1` - ✅ **Consider** (patch update)
   - `dependabot/pip/psutil-7.0.0` - ⚠️ **Review** (major version bump)
   - `dependabot/pip/pyyaml-6.0.2` - ✅ **Consider** (patch update)
   - `dependabot/pip/imageio-ffmpeg-0.6.0` - ⚠️ **Review** (minor version bump)
   - `dependabot/pip/rotary-embedding-torch-0.8.8` - ⚠️ **Review** (major version bump)

4. **GitHub Actions Updates**:
   - `dependabot/github_actions/docker/build-push-action-6` - ✅ **Consider** (tooling update)

## 🎯 **Recommended Actions:**

### Immediate Steps:
1. **Close Python 3.13 PR** - Incompatible with SeedVR requirements
2. **Review major version bumps** - Test in a separate branch first
3. **Merge safe patches** - Only YAML and minor version updates

### Testing Protocol:
Before merging any dependency updates:

```bash
# Create test branch
git checkout -b test-dependency-updates

# Apply the changes manually
# Edit requirements.txt with new versions

# Test locally (if possible) or on RunPod
./scripts/test_local.sh

# If tests pass, merge the PR
# If tests fail, close the PR
```

## 🔧 **Updated Dependabot Configuration**

I've updated `.github/dependabot.yml` to prevent future issues:

### Changes Made:
- ✅ **Reduced frequency**: Monthly instead of weekly
- ✅ **Fewer PRs**: Max 5 instead of 10
- ✅ **Ignored major updates**: For critical ML packages
- ✅ **Disabled Docker updates**: Python 3.10 is intentional
- ✅ **Added constraints**: Prevents breaking changes

### Packages Protected from Major Updates:
- `transformers` - Core SeedVR dependency
- `diffusers` - Core diffusion model support
- `gradio` - Web interface framework
- `numpy` - Fundamental array operations
- `pillow` - Image processing
- `accelerate` - ML acceleration
- `huggingface-hub` - Model downloads
- `opencv-python` - Video processing
- `imageio` - Media I/O
- `ffmpeg-python` - Video encoding

## 📋 **Version Requirements Explanation**

### Why Fixed Versions?

1. **SeedVR Compatibility**: ByteDance tested specific versions
2. **CUDA Dependencies**: PyTorch 2.4.0 + CUDA 12.1 is the tested combination
3. **Model Loading**: Specific transformers/diffusers versions required
4. **GPU Optimization**: flash_attn and apex wheels are version-specific

### Critical Dependencies:
```
Python: 3.10 (flash_attn wheel compatibility)
PyTorch: 2.4.0 (CUDA 12.1 support)
transformers: 4.38.2 (SeedVR model support)
diffusers: 0.29.1 (tested version)
gradio: 4.44.0 (stable interface)
```

## 🚀 **Safe Update Strategy**

### For Security Updates:
1. **Patch versions** (x.y.Z) - Generally safe
2. **Minor versions** (x.Y.z) - Test thoroughly
3. **Major versions** (X.y.z) - Avoid unless necessary

### For Feature Updates:
1. **Wait for SeedVR updates** - Let ByteDance validate new versions
2. **Test in isolation** - Create separate test environments
3. **Update documentation** - If versions change, update README

### Emergency Security Patches:
If critical security vulnerabilities are found:
1. **Assess impact** - Does it affect the container?
2. **Test quickly** - Create hotfix branch
3. **Deploy fast** - Use manual builds if needed
4. **Document changes** - Update CHANGELOG

## 📞 **When in Doubt**

- **Close the PR** - Better safe than broken
- **Test manually** - Create your own update PR
- **Check SeedVR repo** - See if ByteDance updated versions
- **Ask the community** - GitHub discussions or issues

---

**Remember**: This container needs to work reliably on RunPod with expensive GPU time. It's better to be conservative with updates than to have broken deployments! 🛡️