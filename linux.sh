#!/bin/bash
set -e

# --- Install dependencies ---
sudo apt update
sudo apt install -y git cmake wget python3-pip

# Install huggingface-cli via pip
pip install -U huggingface_hub

# --- Clone llama.cpp ---
if [ ! -d "llama.cpp" ]; then
    git clone https://github.com/ggml-org/llama.cpp.git
fi

cd llama.cpp

# --- Build llama.cpp ---
mkdir -p build
cd build

if [ ! -f ./bin/llama ]; then
    cmake -DGGML_CUDA=ON ..  # Use CUDA if you have an NVIDIA GPU
    cmake --build . --config Release -j$(nproc)
else
    echo "llama.cpp already built"
fi

cd ..

# --- Download model ---
mkdir -p ./models/mistral

if [ ! -f ./models/mistral/Mistral-7B-Instruct-v0.3-Q4_K_M.gguf ]; then
    huggingface-cli download bartowski/Mistral-7B-Instruct-v0.3-GGUF \
       --include "Mistral-7B-Instruct-v0.3-Q4_K_M.gguf" \
       --local-dir ./models/mistral
else
    echo "Model already downloaded"
fi

# --- Run llama-server ---
./build/bin/llama-server \
    -m ./models/mistral/Mistral-7B-Instruct-v0.3-Q4_K_M.gguf \
    --port 8081 \
    --ctx-size 5000 \
    -t $(nproc) \
    -ngl 33
