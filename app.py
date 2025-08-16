import gradio as gr
import subprocess
import os

def run_inference(model_size, video_path, output_dir, seed, res_h, res_w, sp_size):
    """
    Runs the SeedVR inference script with the specified parameters.
    """
    if model_size == "3B":
        script_path = "projects/inference_seedvr2_3b.py"
    else:
        script_path = "projects/inference_seedvr2_7b.py"

    num_gpus = 1  # Assuming a single GPU for now

    command = [
        "torchrun",
        f"--nproc-per-node={num_gpus}",
        script_path,
        "--video_path", video_path,
        "--output_dir", output_dir,
        "--seed", str(seed),
        "--res_h", str(res_h),
        "--res_w", str(res_w),
        "--sp_size", str(sp_size),
    ]

    try:
        process = subprocess.Popen(command, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
        stdout, stderr = process.communicate()
        if process.returncode == 0:
            return f"Inference complete. Output saved to {output_dir}\n\nOutput:\n{stdout}"
        else:
            return f"Error during inference:\n{stderr}"
    except Exception as e:
        return f"An error occurred: {str(e)}"

with gr.Blocks() as demo:
    gr.Markdown("# SeedVR Inference")
    with gr.Row():
        model_size = gr.Dropdown(["3B", "7B"], label="Model Size", value="3B")
    with gr.Row():
        video_path = gr.Textbox(label="Input Video Path", value="examples/paris_eiffel_tower.mp4")
        output_dir = gr.Textbox(label="Output Directory", value="results")
    with gr.Row():
        seed = gr.Number(label="Seed", value=123)
        res_h = gr.Number(label="Output Height", value=512)
        res_w = gr.Number(label="Output Width", value=512)
        sp_size = gr.Number(label="SP Size", value=1)
    with gr.Row():
        run_button = gr.Button("Run Inference")
    with gr.Row():
        output_text = gr.Textbox(label="Output", interactive=False)

    run_button.click(
        fn=run_inference,
        inputs=[model_size, video_path, output_dir, seed, res_h, res_w, sp_size],
        outputs=output_text,
    )

if __name__ == "__main__":
    demo.launch(server_name="0.0.0.0")
