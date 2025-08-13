# Bash Syntax Error and APEX Installation Fix - TASK-2025-01-13-006

## Critical Issues Resolved

### Issue #1: Bash Syntax Error (Line 129)
**Problem**: Extra `fi` statement without matching `if` causing syntax error
- Error: `./run.sh: line 129: syntax error near unexpected token 'fi'`
- **Root Cause**: Improper indentation and structure in nested CUDA installation block
- **Location**: Lines 96-129 in APEX installation section

**Solution Implemented**:
- Removed extra `fi` on line 128
- Fixed indentation of nested `if` statements in CUDA detection block
- Restructured the conditional logic to have proper matching if/fi pairs

### Issue #2: CUDA Toolkit Dependency Conflicts
**Problem**: Full CUDA toolkit installation failing due to `nsight-systems-2023.1.2` dependency on unavailable `libtinfo5`
- Error: `nsight-systems-2023.1.2 : Depends: libtinfo5 but it is not installable`
- **Root Cause**: Visual tools components have unresolvable dependencies in container environment

**Solution Implemented**:
- Modified CUDA installation to use minimal components approach
- Primary install: `cuda-compiler-12-1 cuda-libraries-dev-12-1 cuda-driver-dev-12-1`
- Fallback install: `--no-install-recommends cuda-toolkit-12-1-config-common cuda-compiler-12-1 cuda-libraries-dev-12-1`
- Avoids problematic visual tools while maintaining compilation capability

### Issue #3: Debug Numbering Verification
**Status**: Confirmed all step numbering is consistent at `/9` format
- All steps properly numbered from `[1/9]` through `[9/9]`
- No numbering inconsistencies found in current version

## Technical Implementation

### Fixed Bash Structure
```bash
# Proper nested if structure
if [ -d "/workspace/apex" ] && ! python -c "import apex" 2>/dev/null; then
    echo "DEBUG: Proceeding with Apex installation from /workspace/apex"
    cd /workspace/apex
    
    if command -v nvcc &> /dev/null || [ -n "$CUDA_HOME" ]; then
        # CUDA build logic
    else
        # Python-only build logic
    fi
    
    cd /workspace/SeedVR
fi
```

### Enhanced CUDA Installation Strategy
```bash
# Minimal CUDA components to avoid dependency conflicts
(apt-get install -y cuda-compiler-12-1 cuda-libraries-dev-12-1 cuda-driver-dev-12-1 || \
 apt-get install -y --no-install-recommends cuda-toolkit-12-1-config-common cuda-compiler-12-1 cuda-libraries-dev-12-1)
```

## Files Modified
- `/opt/docker/SeedVR-RunPod/run.sh`: Fixed bash syntax error and enhanced CUDA installation logic

## Expected Behavior
Container execution should now proceed without syntax errors:
```
DEBUG: About to start CUDA/Apex installation step
[5/9] Installing CUDA toolkit and building NVIDIA Apex...
DEBUG: Starting CUDA/Apex installation section
DEBUG: Checking for nvcc command...
DEBUG: nvcc not found, will install CUDA toolkit
      Installing CUDA toolkit...
      CUDA toolkit installed successfully
DEBUG: Checking if NVIDIA Apex is already installed...
DEBUG: /workspace/apex exists but Apex not installed, will build from existing repo
      Apex repository exists. Building from existing source...
      Building Apex with CUDA extensions (this may take several minutes)...
DEBUG: Proceeding with Apex installation from /workspace/apex
      CUDA detected - attempting CUDA build
      Apex installed successfully with CUDA extensions
DEBUG: CUDA/Apex installation section completed
      Done.
[6/9] Patching inference scripts for correct model paths...
```

## Next Steps Required
1. **Container Rebuild**: GitHub Actions must build new container with fixed run.sh
2. **RunPod Testing**: Deploy updated container to RunPod for execution verification
3. **APEX Validation**: Confirm APEX installs successfully with CUDA extensions

## Technical Benefits
- **Syntax Compliance**: Proper bash structure eliminates execution failures
- **Dependency Resolution**: Minimal CUDA installation avoids package conflicts
- **Installation Reliability**: Robust fallback mechanisms ensure container startup success
- **Debug Visibility**: Comprehensive logging enables troubleshooting and verification