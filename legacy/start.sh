#!/bin/bash

# ---------- Create or activate virtual environment ----------
if [ ! -d "mistral_env" ]; then
    python3 -m venv mistral_env
fi

source mistral_env/bin/activate
pip install --upgrade pip

# ---------- Install PyTorch with MPS support ----------
# Use PyTorch CPU wheels with MPS support for Apple Silicon
pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cpu

# ---------- Ensure FastAPI and utilities are installed ----------
pip install fastapi uvicorn[standard] psutil

git clone https://github.com/mistralai/mistral-inference.git
cd mistral-inference
pip install . --no-deps
cd ..

pip install transformers sentencepiece safetensors huggingface_hub
pip install simple-parsing>=0.1.5 fire>=0.6.0 mistral_common>=1.5.4

# ---------- Confirm installation ----------
echo "Installed packages:"
pip list | grep -E "fastapi|torch|mistral_inference|transformers|sentencepiece|safetensors|huggingface_hub"

# ---------- Run the FastAPI server ----------
python3 run_mistral_mps.py


# Activate your venv
source mistral_env/bin/activate