# SeedVR-RunPod Project Overview

## Purpose
SeedVR-RunPod is a lightweight Docker container for deploying SeedVR video restoration models on RunPod cloud platform. It provides a user-friendly Gradio web interface for AI-powered video upscaling and restoration using ByteDance's SeedVR2 models.

## Key Features
- Dual model support: SeedVR2-3B (faster, 24GB VRAM) and SeedVR2-7B (higher quality, 40GB VRAM)
- Gradio web interface on port 7860
- GPU-accelerated inference with CUDA support
- Runtime model downloading and dependency installation
- Automated Docker Hub builds via GitHub Actions
- RunPod cloud platform optimization

## Target Use Cases
- Video restoration and upscaling
- Removing compression artifacts from videos
- Enhancing low-quality video content
- Cloud-based video processing workflows

## Repository Information
- GitHub: https://github.com/sruckh/SeedVR-RunPod
- Docker Hub: gemneye/seedvr-runpod:latest
- License: Apache 2.0 (SeedVR) + MIT (container code)