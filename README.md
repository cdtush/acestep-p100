# ACE-Step P100 (and other P series cards)

A Docker build of ACE-Step 1.5 configured for NVIDIA Tesla P100 GPUs.

## Hardware

Tested on:
- NVIDIA Tesla P100-PCIE-16GB
- Pascal architecture (SM 6.0)
- 16GB VRAM

## Software

- Ubuntu 22.04 container
- CUDA 12.6
- Python 3.11
- PyTorch 2.11.0
- CUDA-enabled PyTorch backend

## Features

- Tesla P100 compatibility
- PyTorch inference backend
- Legacy GPU compatibility adjustments
- CPU offloading support
- FP16 lyric-generation overflow workaround

## Build

docker build --no-cache -t acestep-p100 .

## To run
docker run -d \
  --name acestep \
  --gpus all \
  --restart unless-stopped \
  -p 7860:7860 \
  -p 8001:8001 \
  -v acestep-models:/root/.cache/huggingface \
  -v acestep-outputs:/app/outputs \
  ghcr.io/cdtush/acestep-p100:latest

## Access the interface at:

http://localhost:7860

## Prebuilt Image
Available at:

https://github.com/cdtush?tab=packages

## Disclaimer
This is a community-maintained compatibility build.
It is not an official ACE-Step release.

See the upstream project for its source code and licensing:

https://github.com/ACE-Step/ACE-Step-1.5
EOF
