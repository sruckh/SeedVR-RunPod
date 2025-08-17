# Base Image
FROM nvidia/cuda:12.6.3-cudnn-devel-ubuntu24.04


# Set the working directory
WORKDIR /app

# Copy the scripts to the container
COPY run.sh .
COPY download.py .
COPY app.py .
COPY requirements.txt .
COPY color_fix.py .
COPY inference_seedvr2_3b_modified.py .
COPY inference_seedvr2_7b_modified.py .

# Make the run script executable
RUN chmod +x run.sh

# Set the entrypoint
ENTRYPOINT ["./run.sh"]
