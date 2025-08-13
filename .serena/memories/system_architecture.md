# System Architecture

## Container Architecture
```
Docker Container (python:3.10-slim base)
├── Runtime Setup (run.sh)
│   ├── Clone SeedVR repository
│   ├── Setup Python virtual environment  
│   ├── Install PyTorch and dependencies
│   ├── Install flash-attention and Apex
│   ├── Download AI models (3B and 7B)
│   └── Launch Gradio interface
├── Application Layer (app.py)
│   ├── Model management and selection
│   ├── Video processing pipeline
│   ├── Gradio web interface
│   └── Temporary file handling
├── Utilities
│   ├── download.py (Model downloading)
│   └── color_fix.py (Post-processing)
└── Configuration
    ├── Environment variables
    └── Runtime directories
```

## Data Flow
```
User Upload -> Gradio Interface -> Video Processing Pipeline -> AI Model -> Output Video
     │              │                       │                    │           │
     │              │                       │                    │           │
  Web Browser -> Port 7860 -> temp/input -> SeedVR Model -> temp/output -> Download
```

## Key Components

### Runtime Environment (`run.sh`)
- Sets up complete SeedVR environment from scratch
- Downloads and installs dependencies at container startup
- Handles CUDA toolkit installation and Apex compilation
- Robust error handling and retry logic

### Application Core (`app.py`)
- Gradio web interface for user interaction
- Model selection and availability checking
- Video processing workflow orchestration
- Temporary directory management for processing

### Model Management (`download.py`)
- Downloads SeedVR2-3B and SeedVR2-7B models from Hugging Face
- Handles authentication and progress reporting
- Error handling for network issues

### Post-Processing (`color_fix.py`)
- Color correction utilities for enhanced output
- Adaptive Instance Normalization (AdaIN)
- Wavelet-based color matching

## Deployment Strategy
- **Build Time**: Minimal image with Python and system dependencies
- **Runtime**: Dynamic setup of AI models and specialized libraries
- **Benefits**: Smaller image size, always fresh dependencies
- **Trade-offs**: Longer startup time, network dependency

## GPU Integration
- CUDA 12.1+ support for optimal performance
- Multi-GPU inference with sequence parallelism
- Memory management for large model inference
- Real-time GPU monitoring and verification