# SeedVR Official Architecture Research - 2025-08-15

## Research Mission Completion
Conducted systematic research into SeedVR model architecture and path conventions to solve recurring './ckpts/seedvr2_ema_3b.pth' not found errors.

## Key Findings

### 1. Industry Standard Model Path Conventions
From Context7 research on Stability AI (the leader in video diffusion models):

**Standard Pattern**: `checkpoints/` directory structure
- Stability AI uses: `checkpoints/sv3d_u.safetensors`, `checkpoints/sv4d.safetensors`
- Models placed directly in root `checkpoints/` directory
- No nested subdirectories for different model sizes
- Consistent naming: `model_name.safetensors` or `model_name.pth`

**Key Insight**: Industry standard is flat structure, not nested by model size.

### 2. SeedVR Current Implementation Analysis
From serena project analysis:

**Current Download Structure** (in download.py):
```
ckpts/
├── SeedVR2-3B/
│   ├── seedvr2_ema_3b.pth
│   └── ema_vae.pth
└── SeedVR2-7B/
    ├── seedvr2_ema_7b.pth
    └── ema_vae.pth
```

**Code Expectations** (from error analysis):
```
./ckpts/seedvr2_ema_3b.pth  ← Expected by inference code
./ckpts/ema_vae.pth         ← Expected by inference code
```

### 3. Architectural Mismatch Identified

**Root Cause**: Nested directory structure conflicts with flat path expectations
- Download creates nested `SeedVR2-3B/` and `SeedVR2-7B/` subdirectories
- Original SeedVR code expects flat structure like industry standard
- Creates systematic path resolution failures across all model files

### 4. Container vs Local Development Differences

**Container Environment** (`/workspace/SeedVR/`):
- Working directory: `/workspace/SeedVR/`
- Model path: `./ckpts/` resolves to `/workspace/SeedVR/ckpts/`
- Container clones official SeedVR repo preserving original path structure

**RunPod Deployment Specifics**:
- Runtime model downloading (not build-time)
- Models downloaded to subdirectories for organization
- Creates mismatch with original code expectations

### 5. Model Dependency Relationships Mapped

**VAE Model Sharing Discovery**:
- `ema_vae.pth` identical between 3B and 7B models (confirmed in memories)
- VAE handles same latent space regardless of model size
- Single VAE can serve both models efficiently

**Main Model Dependencies**:
- `seedvr2_ema_3b.pth` → requires `ema_vae.pth`
- `seedvr2_ema_7b.pth` → requires `ema_vae.pth` (same file)
- Both models share VAE architecture

### 6. ByteDance Intended Path Management

**Original SeedVR Repository Structure** (inferred from errors):
```
SeedVR/
├── ckpts/
│   ├── seedvr2_ema_3b.pth
│   ├── seedvr2_ema_7b.pth
│   └── ema_vae.pth
├── projects/
│   ├── inference_seedvr2_3b.py
│   ├── inference_seedvr2_7b.py
│   └── video_diffusion_sr/infer.py
```

**Path Convention Analysis**:
- Flat `ckpts/` directory structure
- Direct file access via `./ckpts/filename.pth`
- No nested subdirectories by model size
- Follows industry standard patterns

### 7. Current Solution Assessment

**Existing Fix in download.py** (from memories):
```python
# Copy VAE file to expected location
source_vae = "ckpts/SeedVR2-3B/ema_vae.pth" 
target_vae = "ckpts/ema_vae.pth"
shutil.copy2(source_vae, target_vae)
```

**Status**: Partial solution
- ✅ Fixes VAE path issue
- ❌ Doesn't address main model path mismatches
- ❌ Maintains nested structure causing other issues

### 8. Recommended Architectural Alignment

**Industry Standard Compliance**:
```
ckpts/
├── seedvr2_ema_3b.pth    ← Direct access
├── seedvr2_ema_7b.pth    ← Direct access  
└── ema_vae.pth           ← Shared VAE
```

**Benefits**:
- Aligns with Stability AI and industry standards
- Eliminates all path resolution issues
- Simplifies model loading logic
- Reduces container size (no duplicate VAE)
- Matches original ByteDance SeedVR expectations

### 9. Implementation Strategy

**Phase 1**: Update download.py to use flat structure
- Download to temporary subdirectories
- Copy/move files to flat ckpts/ structure
- Single VAE copy operation

**Phase 2**: Remove sed patching complexity
- Eliminate all path patching in run.sh
- Code works with original paths unchanged
- Cleaner, more maintainable solution

### 10. Evidence-Based Conclusions

**Path Management Best Practices**:
1. Follow industry standards (Stability AI patterns)
2. Align file structure with code expectations
3. Minimize architectural changes to original code
4. Use flat directory structures for model checkpoints
5. Share common components (VAE) across model variants

**Technical Debt Reduction**:
- Replace complex sed patching with structural alignment
- Eliminate maintenance burden of path management
- Create sustainable, scalable solution
- Reduce deployment complexity

## Next Steps
1. Implement flat ckpts/ structure in download.py
2. Remove sed patches from run.sh  
3. Test with both 3B and 7B models
4. Validate RunPod deployment compatibility
5. Document new architecture for maintainability