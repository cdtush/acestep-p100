# Tesla P100 / Pascal compatible CUDA environment
LABEL org.opencontainers.image.source https://github.com/cdtush/acestep-p100:latest
FROM nvidia/cuda:12.6.3-runtime-ubuntu22.04

ENV DEBIAN_FRONTEND=noninteractive
ENV PYTHONUNBUFFERED=1
ENV PYTHONDONTWRITEBYTECODE=1
# ENV ACESTEP_DTYPE="float32"
# CUDA architecture: Tesla P100 = SM 6.0
ENV TORCH_CUDA_ARCH_LIST="6.0"

# Avoid unsupported BF16 and vLLM backends
ENV ACESTEP_LM_BACKEND="pt"

# Install system dependencies and Python 3.11
RUN apt-get update && apt-get install -y \
    software-properties-common \
    ca-certificates \
    curl \
    git \
    ffmpeg \
    libsndfile1 \
    build-essential \
    && add-apt-repository -y ppa:deadsnakes/ppa \
    && apt-get update \
    && apt-get install -y \
        python3.11 \
        python3.11-dev \
        python3.11-venv \
    && rm -rf /var/lib/apt/lists/*

# Create Python virtual environment
RUN python3.11 -m venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"

WORKDIR /app

# Clone ACE-Step 1.5
RUN git clone https://github.com/ACE-Step/ACE-Step-1.5.git .
RUN git fetch --depth=1 origin \
    refs/pull/1352/head:refs/heads/fp16-lyric-fix \
    && git checkout fp16-lyric-fix
# Install a PyTorch version that retains Tesla P100 support
RUN pip install --no-cache-dir --upgrade pip setuptools wheel

RUN pip install --no-cache-dir \
    torch==2.11.0 \
    torchvision==0.26.0 \
    torchaudio==2.11.0 \
    --index-url https://download.pytorch.org/whl/cu126

# Remove dependencies that conflict with our legacy GPU configuration.
# In particular, do not install the repository's CUDA 12.8 PyTorch pins,
# Triton or Flash Attention.
RUN sed -E \
    '/^(--extra-index-url|torch==|torchvision==|torchaudio==|triton>=|flash-attn([[:space:]]|;|$))/d' \
    requirements.txt > /tmp/requirements-p100.txt

# Install the remaining ACE-Step dependencies
RUN pip install --no-cache-dir -r /tmp/requirements-p100.txt

# Install ACE-Step without allowing its pyproject.toml to replace PyTorch
RUN pip install --no-cache-dir --no-deps -e .

# Persistent model and output directories
RUN mkdir -p /app/outputs /app/checkpoints

ENV HF_HOME=/root/.cache/huggingface

EXPOSE 7860
EXPOSE 8001

VOLUME ["/app/outputs", "/app/checkpoints", "/root/.cache/huggingface"]

# Launch ACE-Step using its supported PyTorch backend
CMD ["acestep", "--backend", "pt", "--server-name", "0.0.0.0"]
