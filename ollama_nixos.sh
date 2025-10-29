#!/bin/sh
set -e

# --- Install dependencies ---
# For NixOS, use nix-shell to provide required packages
if [ -z "$IN_NIX_SHELL" ]; then
    export IN_NIX_SHELL=1
    exec nix-shell -p git cmake wget curl python3Packages.huggingface-hub --run "$0 $@"
fi

# --- Clone llama.cpp ---
if [ ! -d "llama.cpp" ] || [ ! -f "llama.cpp/CMakeLists.txt" ]; then
    rm -rf llama.cpp
    git clone https://github.com/ggml-org/llama.cpp.git
fi

cd llama.cpp

# --- Build llama.cpp ---
mkdir -p build
cd build

if [ ! -f ./bin/llama-server ]; then
    if [ ! -f CMakeCache.txt ]; then
        cmake -S .. -B . -DGGML_CUDA=OFF
    fi
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
