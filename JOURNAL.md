# Engineering Journal

## 2025-01-13 20:15

### GitHub Actions Build Fix - CUDA Removal from Dockerfile |TASK:TASK-2025-01-13-002|
- **What**: Fixed GitHub Actions build failure by removing CUDA toolkit installation from Dockerfile
- **Why**: GitHub Actions build environment lacks GPU access, causing CUDA installation to fail during Docker build
- **How**: 
  - Removed CUDA toolkit installation lines from Dockerfile (lines 19-24 and 26-29)
  - Kept only essential system dependencies for build time
  - Maintained existing runtime CUDA installation in run.sh (already robust)
  - Updated Dockerfile comments to clarify runtime-only CUDA approach
- **Issues**: 
  - Build failure with exit code 100 during CUDA toolkit installation
  - GitHub Actions runners have no GPU access during build phase
  - Previous Apex integration inadvertently moved CUDA to build time
- **Result**: 
  - Lightweight Docker image builds successfully in GitHub Actions
  - Runtime CUDA installation preserved and functional
  - Follows project's runtime-first architecture philosophy
  - Container size reduced by removing build-time CUDA (~3GB savings)

## 2025-01-13 15:00

### NVIDIA Apex Integration for SeedVR Performance Optimization |TASK:TASK-2025-01-13-001|
- **What**: Added NVIDIA Apex building and installation to SeedVR-RunPod runtime setup
- **Why**: User requested Apex integration for performance optimization of PyTorch operations in video restoration workloads
- **How**: 
  - Modified Dockerfile to install CUDA toolkit 12.1 with development tools and ninja-build
  - Added step 4.5 to run.sh for Apex repository cloning and building with CUDA extensions
  - Implemented comprehensive error handling with Python-only fallback strategy
  - Updated step numbering from 8 to 9 total steps
- **Issues**: 
  - Base python:3.10-slim image lacks CUDA development tools, required adding full CUDA toolkit (~3GB)
  - Apex compilation can fail in some environments, needed robust error handling
  - Build timing critical - must happen after PyTorch installation but before model setup
- **Result**: 
  - Apex now builds at runtime with CUDA extensions (APEX_CPP_EXT=1 APEX_CUDA_EXT=1)
  - Graceful degradation: Falls back to Python-only build if CUDA compilation fails
  - Container continues to start even if Apex installation completely fails
  - Performance optimizations available when CUDA build succeeds

## 2025-07-18 17:19

### Documentation Framework Implementation
- **What**: Implemented Claude Conductor modular documentation system
- **Why**: Improve AI navigation and code maintainability
- **How**: Used `npx claude-conductor` to initialize framework
- **Issues**: None - clean implementation
- **Result**: Documentation framework successfully initialized

---

