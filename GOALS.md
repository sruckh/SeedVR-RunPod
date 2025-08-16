The MAIN goal of this project is to containerize the upstream project, https://github.com/ByteDance-Seed/SeedVR.git, so that it can run on the RunPod platform.
The is a RUNPOD repackaging project, and not a code rebuilding project.  The code is known to work, it is about containerizing the project so that is can run as a Runpod Container.
use context7 to get documentation on best practices for building runpod container applications.
Use fetch7 to read https://github.com/ByteDance-Seed/SeedVR.git and familiarize yourself with the project
Also use context7 to get up to date documention when necessary

The main container image will just be the base image:  Base Image: nvidia/cuda:12.6.3-cudnn-devel-ubuntu24.04, everything else get's installed at RUNTIME and is not part of the base container.  Everything will be installed on the /workspace filesystem.

Always understand that this Runs in a container on Runpod.  Understand that environment.  Never install any python modules, dependencies, or packages on the VPS server where the code exists.  This project will be built on github, and will be pusshed to dockerhub.

Change the github origin to be https://github.com/sruckh/SeedVR-RunPod.
Use SSH to to communicate with github.
Create github action to build and deploy container image to Dockerhub.  Use the gemneye/ repository.  Use the github secrets DOCKER_USERNAME and DOCKER_PASSWORD for authentication to Dockerhub.

Make sure to understand Container Image Environment, The bootstrap runtime environment, and the python virtual environment.  Know what happens in each environment.

In Runtime install these early on and make sure later they do not get overwritten.
1) Create a python 3.10 virtual environment
2) Torch Version: pip install torch==2.7.0 torchvision==0.22.0 torchaudio==2.7.0
3) flash_attn version: https://github.com/Dao-AILab/flash-attention/releases/download/v2.8.3/flash_attn-2.8.3+cu12torch2.7cxx11abiFALSE-cp311-cp311-linux_x86_64.whl

Next, git clone https://github.com/ByteDance-Seed/SeedVR.git
Change directories to /workspace/SeedVR ;this is working directory

1) pip install -r requirements.txt
2) Install this whl file: https://huggingface.co/ByteDance-Seed/SeedVR2-3B/resolve/main/apex-0.1-cp310-cp310-linux_x86_64.whl
3) put this file, https://github.com/pkuliyi2015/sd-webui-stablesr/blob/master/srmodule/colorfix.py, into the ./projects/video_diffusion_sr/color_fix.py

Create a script to download the AI models to appropriate directories.  You can use the sample below as an example, or use context7 to learn how to using the new hf huggingface module. Both of the models listed below should be downloaded.

ByteDance-Seed/SeedVR2-7B
ByteDance-Seed/SeedVR2-3B

Sample script

from huggingface_hub import snapshot_download

save_dir = "ckpts/"
repo_id = "ByteDance-Seed/SeedVR2-3B"
cache_dir = save_dir + "/cache"

snapshot_download(cache_dir=cache_dir,
  local_dir=save_dir,
  repo_id=repo_id,
  local_dir_use_symlinks=False,
  resume_download=True,
  allow_patterns=["*.json", "*.safetensors", "*.pth", "*.bin", "*.py", "*.md", "*.txt"],
)

This is an example of the inference script
# Take 3B SeedVR2 model inference script as an example
torchrun --nproc-per-node=NUM_GPUS projects/inference_seedvr2_3b.py --video_path INPUT_FOLDER --output_dir OUTPUT_FOLDER --seed SEED_NUM --res_h OUTPUT_HEIGHT --res_w OUTPUT_WIDTH --sp_size NUM_SP

Create a gradio web interface.  The webUI should allow for all the parameters used in the inference_seedvr2_7b.py and inference_seedvr2_3b.py scripts.
