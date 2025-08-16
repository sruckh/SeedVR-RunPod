# SeedVR Script Path Validation - Comprehensive Analysis

## Current Error State
- **Primary Issue**: `./ckpts/seedvr2_ema_3b.pth` missing during model loading
- **Error Chain**: `inference_seedvr2_3b.py:77 → infer.py:89`
- **Previous Pattern**: Similar to VAE path fix where download structure ≠ code expectations

## Path Architecture Analysis

### Download.py Structure (CURRENT - Working for VAE)
- **Downloads to**: `ckpts/SeedVR2-3B/seedvr2_ema_3b.pth` and `ckpts/SeedVR2-7B/seedvr2_ema_7b.pth`
- **VAE Fix Applied**: Copies `ckpts/SeedVR2-3B/ema_vae.pth` → `ckpts/ema_vae.pth`
- **Working Directory**: `/workspace/SeedVR` (all operations relative to this)

### Inference Script Expectations (DETECTED FROM RUN.SH PATCHES)
**From `run_original.sh` sed patterns, the original code expects:**

#### 1. Main Model Files
- **3B Model**: `./ckpts/seedvr2_ema_3b.pth` (relative path)
- **7B Model**: `./ckpts/seedvr2_ema_7b.pth` (relative path)

#### 2. VAE Model (ALREADY FIXED)
- **Expected**: `./ckpts/ema_vae.pth` (relative path)
- **Status**: ✅ RESOLVED via architectural download.py fix

#### 3. Script Locations Expecting Patches
- **Primary**: `projects/inference_seedvr2_3b.py` (line 77 reference)
- **Primary**: `projects/inference_seedvr2_7b.py`
- **Secondary**: `projects/video_diffusion_sr/infer.py` (line 89 reference)
- **Wildcard**: Any `projects/**/*.py` files with hardcoded paths

## Current Solution State

### Current run.sh Implementation
- **Status**: 🚫 REMOVED all sed patching (lines 84-108 from run_original.sh)
- **Current Strategy**: "Model paths handled architecturally in download process"
- **Problem**: Only VAE architectural fix applied, main models still have mismatch

### GAP IDENTIFIED: Missing Main Model Architectural Fix
- **VAE**: ✅ Fixed architecturally in download.py
- **Main Models**: ❌ NOT fixed - still expects relative paths but download.py creates subdirectory structure

## Required Systematic Resolution

### Pattern Analysis from VAE Success
The VAE fix succeeded because:
1. **Single file copy**: `ema_vae.pth` identical across 3B/7B models
2. **Architectural placement**: File copied to exact expected location
3. **No code patching**: Original SeedVR code unchanged

### Main Model Challenge
Unlike VAE, the main models are:
1. **Model-specific**: `seedvr2_ema_3b.pth` ≠ `seedvr2_ema_7b.pth`
2. **Size-different**: Cannot share files between models
3. **Path-specific**: Code expects different filenames for different models

## Systematic Error Resolution Strategy

### Option 1: Complete Architectural Fix (RECOMMENDED)
**Extend download.py pattern:**
```python
# After downloading to subdirectories, copy main models to expected locations
shutil.copy2("ckpts/SeedVR2-3B/seedvr2_ema_3b.pth", "ckpts/seedvr2_ema_3b.pth")
shutil.copy2("ckpts/SeedVR2-7B/seedvr2_ema_7b.pth", "ckpts/seedvr2_ema_7b.pth")
```

**Advantages:**
- Consistent with successful VAE fix approach
- No code patching required
- Clean separation of download vs code concerns
- Maintains original SeedVR code integrity

**Disadvantages:**
- Disk space: Duplicates large model files (~1-2GB each)
- Storage: Total footprint increases significantly

### Option 2: Revert to Code Patching (BACKUP)
**Restore sed patching in run.sh after git clone:**
- Target timing: After git clone, before model download
- Patch all hardcoded paths to absolute paths
- Previous attempts failed due to timing and escaping issues

**Advantages:**
- No file duplication
- Smaller storage footprint

**Disadvantages:**
- Failed 4 times previously
- Complex timing dependencies
- Fragile sed pattern maintenance
- Modifies upstream SeedVR code

### Option 3: Hybrid Approach
**Smart symlinks with architectural verification:**
- Create symlinks instead of copies
- Verify symlink targets exist
- Fallback to copies if symlinks fail

## Implementation Path Forward

### Phase 1: Analyze Current State
1. ✅ Confirm VAE fix working
2. 🔄 Identify specific main model path mismatches
3. 🔄 Map all hardcoded path references in inference scripts
4. 🔄 Validate download.py placement vs ALL script expectations

### Phase 2: Apply Architectural Fix
1. Extend download.py with main model copies (following VAE pattern)
2. Add disk space verification before copies
3. Test with both 3B and 7B model scenarios
4. Verify complete path chain: app.py → inference_*.py → infer.py

### Phase 3: Verification & Documentation
1. Document complete path architecture
2. Create disk space impact analysis
3. Validate all error paths resolved
4. Update memory with final solution

## Key Learning from VAE Fix
**Architecture beats patching** - The VAE success proves that adapting the environment to code expectations is more reliable than trying to patch the code to match the environment.

## Next Actions Required
1. Implement main model architectural fix in download.py
2. Test complete inference chain
3. Document storage implications
4. Create fallback strategy for disk space constraints