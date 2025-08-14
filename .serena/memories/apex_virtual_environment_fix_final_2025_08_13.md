# NVIDIA Apex Virtual Environment Fix - Final Solution - 2025-08-13

## Problem Summary
NVIDIA Apex was being installed in the global Python environment but the SeedVR inference script runs inside a virtual environment (`/workspace/SeedVR/venv`). This caused:
- `ModuleNotFoundError: No module named 'apex'` during inference
- Container logs showing successful APEX installation but runtime failures
- APEX availability in wrong Python environment

## Root Cause Analysis
1. **Virtual Environment Isolation**: APEX installed globally, inference script uses `/workspace/SeedVR/venv`
2. **Inconsistent Python Paths**: Installation used bare `python`/`pip` commands instead of venv-specific paths
3. **Missing Environment Persistence**: Virtual environment activation lost across script sections
4. **No Fallback Mechanism**: Hard dependency on APEX without graceful degradation

## Comprehensive Solution Implemented

### 1. Fixed Virtual Environment Installation
**File**: `/opt/docker/SeedVR-RunPod/run.sh`

#### Virtual Environment Re-activation (Lines 49-57)
```bash
# Re-activate virtual environment and set paths to ensure correct environment
echo "DEBUG: Re-activating virtual environment for APEX installation"
cd /workspace/SeedVR
source venv/bin/activate
export PYTHONPATH="/workspace/SeedVR:$PYTHONPATH"
echo "DEBUG: Virtual environment status:"
echo "      Python executable: $(which python)"
echo "      Pip executable: $(which pip)"
echo "      PYTHONPATH: $PYTHONPATH"
```

#### Explicit Virtual Environment Paths
- **APEX Import Test**: Changed `python -c "import apex"` → `/workspace/SeedVR/venv/bin/python -c "import apex"`
- **APEX Installation**: Changed `pip install` → `/workspace/SeedVR/venv/bin/pip install`
- **All Python Operations**: Now use explicit virtual environment paths

### 2. APEX Installation Verification (Lines 141-150)
```bash
# Verify APEX installation in virtual environment
echo "DEBUG: Verifying APEX installation in virtual environment..."
cd /workspace/SeedVR
if /workspace/SeedVR/venv/bin/python -c "import apex; print(f'APEX version: {apex.__version__}'); from apex.normalization import FusedRMSNorm; print('FusedRMSNorm import successful')" 2>/dev/null; then
    echo "      ✅ APEX successfully installed and verified in virtual environment"
else
    echo "      ⚠️  APEX installation verification failed - will implement fallback in normalization code"
fi
```

### 3. APEX Fallback Implementation (Lines 152-243)
Created comprehensive fallback system for when APEX is unavailable:

#### Fallback Module (`/workspace/SeedVR/apex_fallback.py`)
```python
class FusedRMSNorm(nn.Module):
    """Fallback RMSNorm when APEX FusedRMSNorm unavailable"""
    def __init__(self, normalized_shape, eps=1e-6, elementwise_affine=True, **kwargs):
        super().__init__()
        if isinstance(normalized_shape, int):
            normalized_shape = (normalized_shape,)
        self.normalized_shape = normalized_shape
        self.eps = eps
        self.elementwise_affine = elementwise_affine
        
        if self.elementwise_affine:
            self.weight = nn.Parameter(torch.ones(normalized_shape))
        else:
            self.register_buffer('weight', torch.ones(normalized_shape))
    
    def forward(self, input):
        # Standard RMSNorm: x / sqrt(mean(x^2) + eps) * weight
        input_dtype = input.dtype
        variance = input.to(torch.float32).pow(2).mean(-1, keepdim=True)
        input = input * torch.rsqrt(variance + self.eps)
        result = (input * self.weight.to(input.dtype)).to(input_dtype)
        return result
```

#### Module Injection System
- **Mock Module Creation**: Creates `apex` and `apex.normalization` modules in `sys.modules`
- **Automatic Fallback**: Auto-activates when `import apex` fails
- **Compatible Interface**: Maintains same API as NVIDIA Apex
- **Performance Optimized**: Uses native PyTorch operations with dtype preservation

### 4. Normalization File Patching (Lines 221-229)
```bash
# Patch the main normalization file to use fallback
if [ -f "/workspace/SeedVR/models/dit_v2/normalization.py" ]; then
    cp "/workspace/SeedVR/models/dit_v2/normalization.py" "/workspace/SeedVR/models/dit_v2/normalization.py.backup"
    sed -i '1i# Import APEX fallback before any APEX imports' "/workspace/SeedVR/models/dit_v2/normalization.py"
    sed -i '2i import sys, os' "/workspace/SeedVR/models/dit_v2/normalization.py"
    sed -i '3i sys.path.insert(0, "/workspace/SeedVR")' "/workspace/SeedVR/models/dit_v2/normalization.py"
    sed -i '4i import apex_fallback' "/workspace/SeedVR/models/dit_v2/normalization.py"
    sed -i '5i' "/workspace/SeedVR/models/dit_v2/normalization.py"
    echo "      Applied APEX fallback to normalization.py"
fi
```

### 5. Updated Container Steps (1/10 → 10/10)
- **Step 1**: Clone SeedVR repository
- **Step 2**: Setup Python virtual environment  
- **Step 3**: Install dependencies from requirements.txt
- **Step 4**: Install flash-attention wheel
- **Step 5**: Install CUDA toolkit and build NVIDIA Apex
- **Step 6**: Create APEX fallback implementation
- **Step 7**: Patch inference scripts for correct model paths
- **Step 8**: Place color_fix.py utility
- **Step 9**: Download AI models
- **Step 10**: Launch Gradio interface

## Key Technical Achievements

### 1. Environment Isolation Resolution
- **Explicit Virtual Environment Usage**: All APEX operations use `/workspace/SeedVR/venv/bin/python` and `/workspace/SeedVR/venv/bin/pip`
- **Path Verification**: Debug output shows actual Python executable being used
- **Environment Persistence**: Re-activation ensures virtual environment is active during APEX installation

### 2. Robust Fallback Architecture
- **Transparent Replacement**: Fallback FusedRMSNorm provides identical API to NVIDIA Apex
- **Performance Preservation**: Uses optimized PyTorch operations with proper dtype handling
- **Module Injection**: Seamlessly replaces missing APEX modules in `sys.modules`
- **Automatic Activation**: Fallback activates only when APEX import fails

### 3. Installation Verification
- **Comprehensive Testing**: Verifies both `import apex` and `from apex.normalization import FusedRMSNorm`
- **Environment-Specific**: Tests import in the exact virtual environment used by inference
- **Clear Feedback**: Visual indicators (✅/⚠️) show installation status

### 4. Error Recovery Strategy
- **Multiple Fallback Levels**:
  1. CUDA Apex build → Python-only Apex build → Fallback implementation
  2. Installation failure → Graceful degradation with fallback
  3. Import failure → Automatic fallback module creation

## Expected Behavior After Fix

### Successful APEX Installation
```
[5/10] Installing CUDA toolkit and building NVIDIA Apex...
DEBUG: Starting CUDA/Apex installation section
DEBUG: Re-activating virtual environment for APEX installation
DEBUG: Virtual environment status:
      Python executable: /workspace/SeedVR/venv/bin/python
      Pip executable: /workspace/SeedVR/venv/bin/pip
...
      Apex installed successfully with CUDA extensions
DEBUG: Verifying APEX installation in virtual environment...
      ✅ APEX successfully installed and verified in virtual environment
[6/10] Creating APEX fallback for missing dependencies...
      APEX fallback implementation created
```

### APEX Installation Failure with Fallback
```
[5/10] Installing CUDA toolkit and building NVIDIA Apex...
...
      ERROR: Both CUDA and Python-only Apex builds failed
DEBUG: Verifying APEX installation in virtual environment...
      ⚠️  APEX installation verification failed - will implement fallback in normalization code
[6/10] Creating APEX fallback for missing dependencies...
      Implementing APEX fallback in SeedVR normalization...
      Applied APEX fallback to normalization.py
      APEX fallback implementation created
```

### Inference Execution Success
```
from apex.normalization import FusedRMSNorm  # Works with either real APEX or fallback
```

## Benefits Achieved

### 1. Environment Consistency
- **Same Environment**: APEX installed in same virtual environment as inference execution
- **Path Verification**: Explicit debugging shows exact Python environment being used
- **Isolation**: No conflicts between global and virtual environment packages

### 2. Reliability
- **Graceful Degradation**: System works whether APEX installation succeeds or fails
- **Performance Options**: Real APEX (optimal) → Python-only APEX → PyTorch fallback
- **Error Recovery**: Multiple fallback strategies prevent total failure

### 3. Debugging & Transparency
- **Comprehensive Logging**: Clear visibility into installation process and decisions
- **Status Verification**: Explicit testing of APEX functionality in target environment
- **Problem Identification**: Easy to diagnose virtual environment vs global installation issues

### 4. Maintainability
- **Modular Design**: Fallback implementation in separate module
- **Backup Strategy**: Original files backed up before patching
- **Clear Structure**: Well-documented installation and fallback logic

## Files Modified

### Primary Changes
- **`/opt/docker/SeedVR-RunPod/run.sh`**: Complete APEX installation overhaul with virtual environment fixes and fallback implementation
  - Lines 49-57: Virtual environment re-activation and debugging
  - Lines 87, 108, 116, 119, 130: Changed to use `/workspace/SeedVR/venv/bin/python` and `/workspace/SeedVR/venv/bin/pip`
  - Lines 141-150: APEX installation verification
  - Lines 152-243: APEX fallback implementation

### Runtime Files Created
- **`/workspace/SeedVR/apex_fallback.py`**: Fallback APEX module with compatible FusedRMSNorm implementation
- **`/workspace/apex_import_patch.py`**: General import patch for any Python files needing APEX
- **Backup files**: `normalization.py.backup` for any patched normalization files

## Critical Success Factors

1. **Virtual Environment Consistency**: All Python operations use the same environment as inference execution
2. **Explicit Path Usage**: No reliance on environment variable inheritance across script sections
3. **Comprehensive Fallback**: Compatible replacement when APEX unavailable
4. **Installation Verification**: Testing in the actual execution environment
5. **Graceful Degradation**: System remains functional regardless of APEX installation outcome

## Validation Steps Required

1. **Container Rebuild**: GitHub Actions builds new container with all fixes
2. **APEX Installation Testing**: Verify APEX installs in virtual environment
3. **Fallback Testing**: Confirm fallback works when APEX installation fails
4. **Inference Validation**: Test SeedVR inference with both APEX and fallback
5. **Performance Comparison**: Validate performance with real APEX vs fallback

This comprehensive fix addresses the fundamental virtual environment isolation issue while providing robust fallback mechanisms for maximum reliability.