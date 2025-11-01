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

CURRENT_DIR=$(pwd)

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
cd api || exit
npm i
node src/index.ts &
NODE_PID=$!

echo "node pid $NODE_PID"

pwd

./../llama.cpp/bin/llama-server \
    -m "$CURRENT_DIR/models/mistral/Mistral-7B-Instruct-v0.3-Q4_K_M.gguf" \
    --port 8081 \
    --ctx-size 5000 \
    -t 100 \
    -ngl 33

trap "echo 'Stopping server...'; kill $NODE_PID 2>/dev/null" EXIT
