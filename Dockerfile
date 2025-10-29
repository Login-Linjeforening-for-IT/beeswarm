FROM ubuntu:22.04

WORKDIR /usr/bin/app

# Install build dependencies
RUN apt-get update && apt-get install -y \
    build-essential cmake git curl libcurl4-openssl-dev

# Copy the llama.cpp source code
COPY ./llama.cpp ./llama.cpp

# Build llama.cpp
WORKDIR /usr/bin/app/llama.cpp
RUN rm -rf build \
    && mkdir build \
    && cd build \
    && cmake .. \
    && make -j$(nproc)

# Expose server port
EXPOSE 8080

ENTRYPOINT ["./build/bin/llama-server", "-m", "./models/mistral/Mistral-7B-Instruct-v0.3-Q4_K_M.gguf", "--port", "8080", "--ctx-size", "8192", "-ngl", "33", "--host", "0.0.0.0"]
