# Engineering Journal

## 2025-08-16 21:06

### SeedVR Containerization for RunPod
- **What**: Containerized the SeedVR project for the RunPod platform.
- **Why**: To create a reproducible and portable environment for running the SeedVR application on RunPod.
- **How**: Created a Dockerfile with a CUDA base image, a run.sh script for runtime dependency installation, a Python script for model downloading, and a Gradio web interface for inference. Also set up a GitHub Action for automated builds and deployments to Docker Hub.
- **Issues**: Encountered missing dependencies for `huggingface_hub` and `gradio`, which were resolved by adding installation steps to the `run.sh` script.
- **Result**: A fully containerized SeedVR application ready for deployment on RunPod.

## 2025-08-16 21:09

### Fixed Build Failure
- **What**: Corrected the `apex` installation and removed redundant commands in `run.sh`.
- **Why**: The previous `apex` wheel was incompatible with Python 3.11, causing the build to fail.
- **How**: Replaced the direct wheel installation with a build from the official NVIDIA apex repository. Also removed duplicate `huggingface_hub` installation and `download.py` execution.
- **Issues**: None.
- **Result**: The container build should now complete successfully.

## 2025-08-16 21:11

### Fixed GitHub Action Authentication
- **What**: Updated the GitHub Action workflow to use the latest versions of the `actions/checkout`, `docker/login-action`, and `docker/build-push-action`.
- **Why**: The previous versions were causing authentication errors with Docker Hub and using deprecated commands.
- **How**: Changed the version numbers of the actions in the `.github/workflows/main.yml` file.
- **Issues**: None.
- **Result**: The GitHub Action should now authenticate with Docker Hub and run without warnings.
