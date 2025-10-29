brew install cmake wget huggingface-cli
git clone https://github.com/ggml-org/llama.cpp.git
cd llama.cpp
mkdir build && cd build
cmake -DGGML_METAL=ON .. && cmake --build . --config Release
hf download bartowski/Mistral-7B-Instruct-v0.3-GGUF --include "Mistral-7B-Instruct-v0.3-Q4_K_M.gguf" --local-dir ./models/mistral
# ./build/bin/llama-cli -m ./models/mistral/Mistral-7B-Instruct-v0.3-Q4_K_M.gguf -i -t 16 -ngl 33 --ctx_size 8192
# python3 -m venv ollama_env
# source ollama_env/bin/activate
# # pip install flask requests
# # python3 ../llama_server.py
./build/bin/llama-server \
    -m ./models/mistral/Mistral-7B-Instruct-v0.3-Q4_K_M.gguf \
    --port 8080 \
    --ctx-size 8192 \
    -ngl 33
