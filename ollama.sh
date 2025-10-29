brew install cmake wget huggingface-cli
git clone https://github.com/ggml-org/llama.cpp.git
cd llama.cpp
mkdir build && cd build

if [ ! -f ./build/bin/llama ]; then
    mkdir -p build
    cd build
    cmake -DGGML_METAL=ON ..
    cmake --build . --config Release
    cd ..
else
    echo "llama.cpp already built"
fi

if [ ! -f ./models/mistral/Mistral-7B-Instruct-v0.3-Q4_K_M.gguf ]; then
    hf download bartowski/Mistral-7B-Instruct-v0.3-GGUF \
       --include "Mistral-7B-Instruct-v0.3-Q4_K_M.gguf" \
       --local-dir ./models/mistral
else
    echo "Model already downloaded"
fi

./build/bin/llama-server \
    -m ./models/mistral/Mistral-7B-Instruct-v0.3-Q4_K_M.gguf \
    --port 8081 \
    --ctx-size 100000 \
    -t 100 \
    -ngl 33
