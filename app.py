import gradio as gr
import os
import subprocess
import shutil

def run_inference(model, video, seed, res_h, res_w, sp_size, out_fps, cfg_scale, cfg_rescale, sample_steps):
    print("--- Running inference ---")
    # Set the input and output paths
    input_path = "/tmp/input_video"
    output_path = "/tmp/output_video"
    os.makedirs(input_path, exist_ok=True)
    os.makedirs(output_path, exist_ok=True)

    # Save the uploaded video
    print(f"Input video: {video.name}")
    video_filename = os.path.join(input_path, os.path.basename(video.name))
    shutil.copy(video.name, video_filename)
    print(f"Video saved to: {video_filename}")

    # Determine which script to run
    if model == "3B":
        script_name = "projects/inference_seedvr2_3b.py"
    elif model == "7B":
        script_name = "projects/inference_seedvr2_7b.py"
    else:
        return "Invalid model selected."
    print(f"Using script: {script_name}")

    # Construct the command
    command = [
        "torchrun",
        "--nproc-per-node=1",
        script_name,
        "--video_path", input_path,
        "--output_dir", output_path,
        "--seed", str(seed),
        "--res_h", str(res_h),
        "--res_w", str(res_w),
        "--sp_size", str(sp_size),
    ]

    if out_fps:
        command.extend(["--out_fps", str(out_fps)])

    print(f"Command: {' '.join(command)}")

    # Set environment variables for the new parameters
    env = os.environ.copy()
    env["CFG_SCALE"] = str(cfg_scale)
    env["CFG_RESCALE"] = str(cfg_rescale)
    env["SAMPLE_STEPS"] = str(sample_steps)

    # Run the command
    try:
        result = subprocess.run(command, check=True, text=True, capture_output=True, env=env)
        print("--- Inference stdout ---")
        print(result.stdout)
        print("--- Inference stderr ---")
        print(result.stderr)
    except subprocess.CalledProcessError as e:
        print(f"Error during inference: {e}")
        print(f"--- Error stdout ---")
        print(e.stdout)
        print(f"--- Error stderr ---")
        print(e.stderr)
        return f"Error: {e.stderr}"

    # Get the output file
    print(f"Output directory content: {os.listdir(output_path)}")
    output_files = os.listdir(output_path)
    if not output_files:
        return "No output file generated."

    output_video_path = os.path.join(output_path, output_files[0])
    print(f"Output video path: {output_video_path}")

    return output_video_path

# Create the Gradio interface
with gr.Blocks() as demo:
    gr.Markdown("# SeedVR Video Restoration")
    with gr.Row():
        with gr.Column():
            model = gr.Dropdown(["3B", "7B"], label="Model", value="3B")
            video = gr.File(label="Input Video")
            seed = gr.Number(label="Seed", value=666)
            res_h = gr.Number(label="Output Height", value=720)
            res_w = gr.Number(label="Output Width", value=1280)
            sp_size = gr.Number(label="SP Size", value=1)
            out_fps = gr.Number(label="Output FPS (optional)", value=None)
            cfg_scale = gr.Slider(minimum=0.0, maximum=2.0, value=1.0, label="CFG Scale")
            cfg_rescale = gr.Slider(minimum=0.0, maximum=1.0, value=0.0, label="CFG Rescale")
            sample_steps = gr.Slider(minimum=1, maximum=10, step=1, value=1, label="Sample Steps")
            run_button = gr.Button("Run Inference")
        with gr.Column():
            output_video = gr.Video(label="Output Video")

    run_button.click(
        fn=run_inference,
        inputs=[model, video, seed, res_h, res_w, sp_size, out_fps, cfg_scale, cfg_rescale, sample_steps],
        outputs=output_video,
    )

if __name__ == "__main__":
    demo.launch(server_name="0.0.0.0", server_port=7860, share=True)