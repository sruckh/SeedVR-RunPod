import gradio as gr
import os
import subprocess
import tempfile
import shutil
from pathlib import Path
import torch

# --- Configuration ---
# This script assumes it's run from the /workspace/SeedVR directory
CKPTS_DIR = Path("./ckpts")
OUTPUT_DIR = Path("./outputs")
TEMP_DIR = Path("./temp")

# --- Helper Functions ---

def check_available_models():
    """Checks for downloaded model directories."""
    available = []
    if (CKPTS_DIR / "SeedVR2-3B").exists():
        available.append("SeedVR2-3B")
    if (CKPTS_DIR / "SeedVR2-7B").exists():
        available.append("SeedVR2-7B")
    return available

def upscale_video(video_path, model_name, height, width, seed, progress=gr.Progress()):
    """
    The main function to upscale a video using the selected SeedVR model.
    """
    if not video_path:
        raise gr.Error("Please upload a video file.")

    if not model_name:
        raise gr.Error("Please select a model.")

    progress(0, desc="Starting...")

    # --- 1. Prepare directories ---
    progress(0.1, desc="Preparing directories...")
    # Create a temporary directory for the input video file
    # The inference script takes a directory as input
    input_video_dir = tempfile.mkdtemp(dir=TEMP_DIR)
    shutil.copy(video_path, input_video_dir)

    # Create a temporary directory for the output
    output_video_dir = tempfile.mkdtemp(dir=TEMP_DIR)

    try:
        # --- 2. Determine inference script and GPU count ---
        progress(0.2, desc="Configuring inference...")
        if model_name == "SeedVR2-3B":
            inference_script = "projects/inference_seedvr2_3b.py"
        elif model_name == "SeedVR2-7B":
            inference_script = "projects/inference_seedvr2_7b.py"
        else:
            raise gr.Error(f"Unknown model: {model_name}")

        if not Path(inference_script).exists():
            raise gr.Error(f"Inference script not found at {inference_script}. Check the repository structure.")

        num_gpus = torch.cuda.device_count() if torch.cuda.is_available() else 1
        if num_gpus == 0:
            # This case should ideally not be hit in a RunPod environment
            raise gr.Error("No GPU detected. SeedVR requires a GPU.")

        # --- 3. Construct and run the inference command ---
        progress(0.3, desc="Running model inference (this can take a while)...")

        cmd = [
            "torchrun",
            f"--nproc-per-node={num_gpus}",
            inference_script,
            "--video_path", str(input_video_dir),
            "--output_dir", str(output_video_dir),
            "--seed", str(seed),
            "--res_h", str(height),
            "--res_w", str(width),
            "--sp_size", str(num_gpus)
        ]

        print(f"Executing command: {' '.join(cmd)}")

        process = subprocess.run(
            cmd,
            capture_output=True,
            text=True,
            check=False
        )

        if process.returncode != 0:
            print("--- STDERR ---")
            print(process.stderr)
            print("--- STDOUT ---")
            print(process.stdout)
            raise gr.Error(f"Inference failed. Check console for details. Error: {process.stderr[:500]}")

        # --- 4. Find and return the output video ---
        progress(0.9, desc="Finalizing...")

        output_files = list(Path(output_video_dir).glob("*.mp4"))
        if not output_files:
            print("--- STDERR ---")
            print(process.stderr)
            print("--- STDOUT ---")
            print(process.stdout)
            raise gr.Error("Inference completed, but no output video was found.")

        # Copy final output to a persistent directory
        final_output_path = OUTPUT_DIR / f"restored_{model_name.replace('/', '_')}_{Path(video_path).stem}.mp4"
        shutil.copy(output_files[0], final_output_path)

        progress(1, desc="Done!")
        return str(final_output_path)

    finally:
        # --- 5. Cleanup temporary directories ---
        shutil.rmtree(input_video_dir, ignore_errors=True)
        shutil.rmtree(output_video_dir, ignore_errors=True)


# --- Gradio UI ---

def create_ui():
    # Ensure output directories exist
    OUTPUT_DIR.mkdir(exist_ok=True)
    TEMP_DIR.mkdir(exist_ok=True)

    models = check_available_models()

    with gr.Blocks(theme=gr.themes.Soft(), title="SeedVR Video Upscaler") as interface:
        gr.Markdown("# 🎬 SeedVR Video Upscaler")
        gr.Markdown("Upscale and restore your videos using the SeedVR models. Select a model, upload a video, and click 'Restore'.")

        with gr.Row():
            with gr.Column(scale=1):
                input_video = gr.Video(label="Input Video", sources=["upload"])

                model_choice = gr.Dropdown(
                    label="Choose Model",
                    choices=models,
                    value=models[0] if models else None,
                    info="7B is higher quality but slower."
                )

                if not models:
                    gr.Markdown("⚠️ **No models found!** Please ensure models were downloaded correctly in the `ckpts` directory.")

                gr.Markdown("### Inference Settings")
                with gr.Row():
                    width = gr.Slider(512, 2048, value=1280, step=64, label="Output Width")
                    height = gr.Slider(512, 2048, value=720, step=64, label="Output Height")

                seed = gr.Slider(0, 100000, value=42, step=1, label="Seed")

                restore_button = gr.Button("🚀 Restore Video", variant="primary")

            with gr.Column(scale=1):
                output_video = gr.Video(label="Restored Video", interactive=False)

        restore_button.click(
            fn=upscale_video,
            inputs=[input_video, model_choice, height, width, seed],
            outputs=[output_video],
            show_progress="full"
        )
    return interface


if __name__ == "__main__":
    app = create_ui()
    # Launch the Gradio app, making it accessible on the network
    app.launch(server_name="0.0.0.0", server_port=7860)
