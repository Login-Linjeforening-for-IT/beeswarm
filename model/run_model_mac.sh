#!/bin/sh

CURRENT_DIR=$(pwd)

# Install cmake if not installed
if ! command -v cmake &> /dev/null; then
    brew install cmake
fi

# Install wget if not installed
if ! command -v wget &> /dev/null; then
    brew install wget
fi

# Install huggingface-cli if not installed
if ! command -v hf &> /dev/null; then
    brew install huggingface-cli
fi

if [ ! -d ./llama.cpp ]; then
    git clone https://github.com/ggml-org/llama.cpp.git
fi

if [ ! -f ./llama.cpp/build/bin/llama ]; then
    cd ./llama.cpp
    cmake -DGGML_METAL=ON -DCMAKE_CXX_STANDARD=17
    cmake --build . --config Release
    cd ..
else
    echo "llama.cpp already built"
fi

if [ ! -f ./llama.cpp/build/models/mistral/Mistral-7B-Instruct-v0.3-Q4_K_M.gguf ]; then
    hf download bartowski/Mistral-7B-Instruct-v0.3-GGUF \
       --include "Mistral-7B-Instruct-v0.3-Q4_K_M.gguf" \
       --local-dir ./models/mistral
else
    echo "Model already downloaded"
fi

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
