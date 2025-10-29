#!/bin/bash
bash <(curl -sSL https://g.bodaay.io/hfd) -h
./hfdownloader -m mistralai/Mistral-7B-Instruct-v0.3
gh repo clone ggerganov/llama.cpp
python3 -m venv mistral_env
source mistral_env/bin/activate
python3 -m pip install -r requirements.txt
python3 convert.py models/mistralai_Mistral-7B-Instruct-v0.2 --outfile models/mistralai_Mistral-7B-Instruct-v0.2/ggml-model-f16.gguf --outtype f16
./quantize models/mistralai_Mistral-7B-Instruct-v0.2/ggml-model-f16.gguf models/mistralai_Mistral-7B-Instruct-v0.2/ggml-model-q4_0.gguf q4_0
./main -m ./models/mistralai_Mistral-7B-Instruct-v0.2/ggml-model-q4_0.gguf -p "I believe the meaning of life is" -ngl 999 -s 1 -n 128 -t 8
