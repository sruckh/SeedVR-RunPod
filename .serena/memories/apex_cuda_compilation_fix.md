# Apex CUDA Compilation Fix - Critical Runtime Restoration

## Issue Summary
After fixing the GitHub Actions build by removing CUDA from the Dockerfile, Apex compilation was completely broken. SeedVR requires NVIDIA Apex for inference performance, making this a critical functionality issue.

## Root Cause
NVIDIA Apex requires CUDA toolkit for compilation from source with C++ and CUDA extensions. When CUDA was removed from the Dockerfile to fix GitHub Actions builds, no runtime CUDA installation was provided for Apex compilation.

## Solution Implemented
1. **Runtime CUDA Installation**: Added CUDA toolkit 12.1 installation to run.sh (lines 47-66)
2. **Enhanced Apex Build**: Improved Apex compilation with comprehensive CUDA detection (lines 81-105)
3. **Official Recommendations**: Implemented NVIDIA's recommended compilation flags (APEX_CPP_EXT=1 APEX_CUDA_EXT=1)
4. **Robust Fallback**: Added Python-only build fallback if CUDA compilation fails

## Technical Implementation

### CUDA Detection and Installation
```bash
if ! command -v nvcc &> /dev/null; then
    echo "Installing CUDA toolkit..."
    # Official NVIDIA CUDA 12.1 installation
    wget https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2004/x86_64/cuda-keyring_1.0-1_all.deb
    dpkg -i cuda-keyring_1.0-1_all.deb
    apt-get update && apt-get install -y cuda-toolkit-12-1
fi
```

### Apex Compilation Strategy
```bash
# NVIDIA official recommendations
APEX_CPP_EXT=1 APEX_CUDA_EXT=1 pip install -v --no-build-isolation --no-cache-dir ./
```

### Fallback Mechanism
- Primary: CUDA build with C++ and CUDA extensions
- Fallback: Python-only build if CUDA compilation fails
- Graceful degradation: Container continues startup even if Apex installation fails

## Benefits
- **SeedVR Compatibility**: Apex now available for inference performance optimizations
- **Build Success**: GitHub Actions builds still succeed (lightweight image)
- **Runtime Flexibility**: CUDA installed only when GPU environment available
- **Performance**: CUDA extensions provide optimal Apex performance
- **Reliability**: Robust error handling ensures container startup success

## Files Changed
- `/opt/docker/SeedVR-RunPod/run.sh`: Enhanced CUDA and Apex installation (lines 44-111)
- `/opt/docker/SeedVR-RunPod/TASKS.md`: Updated current task to TASK-2025-01-13-003
- `/opt/docker/SeedVR-RunPod/JOURNAL.md`: Added detailed fix documentation

## Critical Dependencies
- **SeedVR Inference**: Requires Apex for mixed precision and optimization
- **CUDA 12.1**: Compatible with PyTorch 2.4.0 and SeedVR models
- **Runtime Environment**: GPU access required for CUDA compilation
- **Performance**: C++ and CUDA extensions essential for production workloads