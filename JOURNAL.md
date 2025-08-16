# Engineering Journal

## 2025-08-16 21:06

### SeedVR Containerization for RunPod
- **What**: Containerized the SeedVR project for the RunPod platform.
- **Why**: To create a reproducible and portable environment for running the SeedVR application on RunPod.
- **How**: Created a Dockerfile with a CUDA base image, a run.sh script for runtime dependency installation, a Python script for model downloading, and a Gradio web interface for inference. Also set up a GitHub Action for automated builds and deployments to Docker Hub.
- **Issues**: Encountered missing dependencies for `huggingface_hub` and `gradio`, which were resolved by adding installation steps to the `run.sh` script.
- **Result**: A fully containerized SeedVR application ready for deployment on RunPod.
