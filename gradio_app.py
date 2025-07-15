#!/usr/bin/env python3
"""
SeedVR Gradio Interface
Supports both SeedVR2-3B and SeedVR2-7B models for video restoration
"""

import os
import sys
import gradio as gr
import torch
import tempfile
import shutil
from pathlib import Path
import subprocess
import time
from typing import Optional, Tuple
import logging

# Setup logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Add SeedVR to path
sys.path.append('/workspace')
sys.path.append('/workspace/projects')

class SeedVRProcessor:
    def __init__(self):
        self.current_model = None
        self.model_loaded = False
        self.available_models = self.check_available_models()
        
    def check_available_models(self) -> list:
        """Check which models are available"""
        models = []
        ckpts_dir = Path("/workspace/ckpts")
        
        if (ckpts_dir / "3B").exists():
            models.append("SeedVR2-3B")
        if (ckpts_dir / "7B").exists():
            models.append("SeedVR2-7B")
            
        return models
    
    def load_model(self, model_name: str) -> bool:
        """Load the specified model"""
        try:
            if model_name == self.current_model and self.model_loaded:
                return True
                
            logger.info(f"Loading model: {model_name}")
            
            # Clear GPU memory
            if torch.cuda.is_available():
                torch.cuda.empty_cache()
            
            self.current_model = model_name
            self.model_loaded = True
            
            return True
            
        except Exception as e:
            logger.error(f"Error loading model {model_name}: {str(e)}")
            self.model_loaded = False
            return False
    
    def process_video(self, 
                     input_video: str, 
                     model_name: str,
                     output_height: int = 720,
                     output_width: int = 1280,
                     seed: int = 42,
                     fps: int = 24,
                     progress=gr.Progress()) -> Optional[str]:
        """Process video using the selected model"""
        
        if not input_video:
            return None
            
        if model_name not in self.available_models:
            raise gr.Error(f"Model {model_name} not available. Available models: {self.available_models}")
        
        # Load model if needed
        progress(0.1, desc="Loading model...")
        if not self.load_model(model_name):
            raise gr.Error(f"Failed to load model {model_name}")
        
        # Create temporary output directory
        output_dir = tempfile.mkdtemp(dir="/workspace/temp")
        
        try:
            progress(0.2, desc="Preparing video...")
            
            # Copy input video to workspace
            input_path = Path(input_video)
            temp_input = Path("/workspace/temp") / f"input_{int(time.time())}{input_path.suffix}"
            shutil.copy2(input_video, temp_input)
            
            progress(0.3, desc="Starting video restoration...")
            
            # Determine number of GPUs and inference script
            num_gpus = torch.cuda.device_count() if torch.cuda.is_available() else 1
            
            if model_name == "SeedVR2-3B":
                script_filename = "inference_seedvr2_3b.py"
            else:  # SeedVR2-7B
                script_filename = "inference_seedvr2_7b.py"
            
            # Check multiple possible locations for the script
            possible_paths = [
                f"/workspace/projects/{script_filename}",
                f"/workspace/SeedVR/projects/{script_filename}",
                f"/workspace/{script_filename}"
            ]
            
            script_path = None
            for path in possible_paths:
                if Path(path).exists():
                    script_path = path
                    break
            
            if not script_path:
                logger.error(f"Inference script {script_filename} not found in any expected location:")
                for path in possible_paths:
                    logger.error(f"  - {path} (exists: {Path(path).exists()})")
                logger.error("Available files in /workspace/:")
                for file in Path("/workspace").glob("**/*.py"):
                    logger.error(f"  - {file}")
                raise gr.Error(f"Inference script {script_filename} not found. Please check container setup.")
            
            # Build command (Note: FPS is handled during output processing, not inference)
            cmd = [
                "torchrun",
                f"--nproc-per-node={num_gpus}",
                script_path,
                "--video_path", str(temp_input.parent),
                "--output_dir", output_dir,
                "--seed", str(seed),
                "--res_h", str(output_height),
                "--res_w", str(output_width),
                "--sp_size", str(num_gpus)
            ]
            
            # Run inference
            progress(0.4, desc="Running inference (this may take several minutes)...")
            logger.info(f"Running command: {' '.join(cmd)}")
            
            result = subprocess.run(
                cmd,
                cwd="/workspace",
                capture_output=True,
                text=True,
                timeout=1800  # 30 minute timeout
            )
            
            if result.returncode != 0:
                logger.error(f"Inference failed: {result.stderr}")
                raise gr.Error(f"Video processing failed: {result.stderr}")
            
            progress(0.9, desc="Finalizing output...")
            
            # Find output video
            output_files = list(Path(output_dir).glob("*.mp4"))
            if not output_files:
                raise gr.Error("No output video generated")
            
            output_video = output_files[0]
            
            # Copy to final location
            final_output = Path("/workspace/outputs") / f"restored_{int(time.time())}.mp4"
            shutil.copy2(output_video, final_output)
            
            progress(1.0, desc="Complete!")
            
            # Cleanup temp files
            temp_input.unlink(missing_ok=True)
            
            return str(final_output)
            
        except subprocess.TimeoutExpired:
            raise gr.Error("Video processing timed out (30 minutes). Try with a shorter video or lower resolution.")
        except Exception as e:
            logger.error(f"Error processing video: {str(e)}")
            raise gr.Error(f"Error processing video: {str(e)}")
        finally:
            # Cleanup temporary directory
            shutil.rmtree(output_dir, ignore_errors=True)

# Global processor variable
processor = None

def get_processor():
    """Get or create the processor instance"""
    global processor
    if processor is None:
        try:
            processor = SeedVRProcessor()
            logger.info("✅ SeedVRProcessor initialized successfully")
        except Exception as e:
            logger.error(f"❌ Failed to initialize SeedVRProcessor: {e}")
            # Create a dummy processor with empty models
            def dummy_process_video(self, input_video, model_name, output_height=720, output_width=1280, seed=42, fps=24, progress=None):
                raise gr.Error("❌ Model initialization failed. Please check container logs.")
            
            processor = type('DummyProcessor', (), {
                'available_models': [],
                'current_model': None,
                'model_loaded': False,
                'load_model': lambda self, x: False,
                'process_video': dummy_process_video
            })()
    return processor

def create_interface():
    """Create and return the Gradio interface"""
    
    # Get processor instance
    proc = get_processor()
    
    with gr.Blocks(title="SeedVR Video Restoration", theme=gr.themes.Soft()) as app:
        
        gr.Markdown("""
        # 🎬 SeedVR Video Restoration
        
        Upload a video and restore it using state-of-the-art diffusion models.
        Supports both **SeedVR2-3B** (faster) and **SeedVR2-7B** (higher quality) models.
        """)
        
        # Show available models
        if proc.available_models:
            gr.Markdown(f"**Available Models:** {', '.join(proc.available_models)}")
        else:
            gr.Markdown("⚠️ **No models found!** Please ensure models are downloaded.")
        
        with gr.Row():
            with gr.Column(scale=1):
                gr.Markdown("### Input")
                
                input_video = gr.Video(
                    label="Upload Video",
                    sources=["upload"]
                )
                
                model_choice = gr.Dropdown(
                    choices=proc.available_models,
                    value=proc.available_models[0] if proc.available_models else None,
                    label="Model",
                    info="SeedVR2-3B is faster, SeedVR2-7B has higher quality"
                )
                
                with gr.Row():
                    output_width = gr.Slider(
                        minimum=512,
                        maximum=2048,
                        value=1280,
                        step=64,
                        label="Output Width"
                    )
                    
                    output_height = gr.Slider(
                        minimum=512,
                        maximum=2048,
                        value=720,
                        step=64,
                        label="Output Height"
                    )
                
                seed = gr.Slider(
                    minimum=0,
                    maximum=100000,
                    value=42,
                    step=1,
                    label="Random Seed"
                )
                
                fps = gr.Number(
                    label="FPS",
                    value=24,
                    minimum=1,
                    maximum=120,
                    info="Frames per second for output video"
                )
                
                restore_btn = gr.Button(
                    "🚀 Restore Video",
                    variant="primary",
                    size="lg"
                )
                
            with gr.Column(scale=1):
                gr.Markdown("### Output")
                
                output_video = gr.Video(
                    label="Restored Video",
                    interactive=False
                )
                
                gr.Markdown("""
                ### 📝 Notes
                - Processing time depends on video length and resolution
                - Higher resolution outputs require more GPU memory
                - SeedVR2-7B produces better quality but takes longer
                - Maximum processing time: 30 minutes
                """)
        
        # Examples section
        gr.Markdown("### 📋 Tips")
        gr.Markdown("""
        - **Best results**: Videos with compression artifacts, low resolution, or quality issues
        - **Recommended resolution**: 720p-1080p for optimal speed/quality balance
        - **Video format**: MP4 works best
        - **Length**: Shorter videos (< 30 seconds) process faster
        """)
        
        # Event handlers
        restore_btn.click(
            fn=proc.process_video,
            inputs=[input_video, model_choice, output_height, output_width, seed, fps],
            outputs=output_video,
            show_progress="full"
        )
    
    return app

def main():
    """Main function to launch the Gradio app"""
    
    # Initialize processor and check models
    proc = get_processor()
    if not proc.available_models:
        logger.warning("No models found! The interface will still launch but video processing will not work.")
    
    logger.info(f"Available models: {proc.available_models}")
    
    # Parse environment variables
    share_gradio = os.getenv('GRADIO_SHARE', 'false').lower() in ('true', '1', 'yes', 'on')
    server_port = int(os.getenv('GRADIO_PORT', '7860'))
    server_name = os.getenv('GRADIO_HOST', '0.0.0.0')
    
    logger.info(f"Gradio configuration:")
    logger.info(f"  Host: {server_name}")
    logger.info(f"  Port: {server_port}")
    logger.info(f"  Share: {share_gradio}")
    
    # Create and launch interface
    app = create_interface()
    
    app.launch(
        server_name=server_name,
        server_port=server_port,
        share=share_gradio,
        show_error=True,
        max_threads=4
    )

if __name__ == "__main__":
    main()