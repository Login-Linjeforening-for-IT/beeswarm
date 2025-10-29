#!/usr/bin/env bash
set -euo pipefail

# install_and_run_api.sh
# Usage: ./install_and_run_api.sh
# This script:
#  1) Creates a venv
#  2) Installs build deps (Homebrew)
#  3) Clones onnxruntime-genai and checks out v0.3.0
#  4) Downloads a matching ONNX Runtime macOS arm64 release (v1.19.0 as in the guide)
#  5) Builds the onnxruntime-genai wheel and installs it
#  6) Installs python deps, downloads Phi-3 (or Mistral) ONNX CPU files
#  7) Writes a FastAPI wrapper (server.py)
#  8) Launches uvicorn on port 8080

# NOTE: This script is best run on Apple Silicon macOS with Xcode tools installed.
# You may be prompted to install Homebrew packages and to login to Hugging Face for large model files.

WORKDIR="${PWD}/onnx_local_api"
PYTHON_BIN="$(which python3 || true)"
PORT=8080

echo "Creating workdir: ${WORKDIR}"
mkdir -p "${WORKDIR}"
cd "${WORKDIR}"

# 1) Python & venv
if ! command -v python3 >/dev/null 2>&1; then
  echo "python3 not found. Install Python 3.12+ (homebrew: brew install python) and re-run."
  exit 1
fi

echo "Creating virtualenv..."
python3.12 -m venv venv
# shellcheck disable=SC1091
source venv/bin/activate

pip install --upgrade pip

# 2) Homebrew build tools (if brew exists)
if command -v brew >/dev/null 2>&1; then
  echo "Installing build tools via brew..."
  brew install -q cmake curl wget gzip git git-lfs || true
  # make sure git-lfs is installed and configured
  git lfs install || true
else
  echo "Homebrew not found; assume required build tools are present. If build fails, install brew and rerun."
fi

# 3) Clone onnxruntime-genai and checkout v0.3.0 (as in the article)
if [ ! -d "onnxruntime-genai" ]; then
  echo "Cloning onnxruntime-genai..."
  git clone https://github.com/microsoft/onnxruntime-genai.git onnxruntime-genai
fi
cd onnxruntime-genai
git fetch --tags || true
# prefer v0.3.0 because article used it
git checkout tags/v0.3.0 -f || git checkout main || true
git status --porcelain -b || true
cd ..

# 4) Download ONNX Runtime macOS arm64 prebuilt (the article used v1.19.0)
ORT_TGZ="onnxruntime-osx-arm64-1.19.0.tgz"
if [ ! -d "onnxruntime-genai/ort" ]; then
  echo "Downloading ONNX Runtime macOS (arm64) v1.19.0..."
  # try direct GitHub release download, fallback to curl
  if ! wget -q -O "${ORT_TGZ}" "https://github.com/microsoft/onnxruntime/releases/download/v1.19.0/onnxruntime-osx-arm64-1.19.0.tgz"; then
    echo "wget failed to fetch ONNX Runtime v1.19.0; please download manually and place as ${ORT_TGZ} in ${WORKDIR}"
    exit 1
  fi
  tar -xzvf "${ORT_TGZ}"
  mv onnxruntime-osx-arm64-1.19.0 onnxruntime-genai/ort
fi

# 5) Build onnxruntime-genai
cd onnxruntime-genai
echo "Running build.sh (this can take a long time)..."
# use the same command as the article
sh build.sh --build_dir=build/macOS --config=RelWithDebInfo

# find wheel
WHEEL_DIR="build/macOS/RelWithDebInfo/wheel"
WHEEL_PATH=$(ls ${WHEEL_DIR}/onnxruntime_genai-*.whl 2>/dev/null | head -n1 || true)
if [ -z "${WHEEL_PATH}" ]; then
  echo "Could not find built wheel in ${WHEEL_DIR}. Build may have failed. Inspect build logs."
  exit 1
fi
echo "Found wheel: ${WHEEL_PATH}"

# 6) Install the built wheel + numpy + other python deps
pip install numpy
pip install "${WHEEL_PATH}"

# install additional app deps
pip install "huggingface_hub[cli]" fastapi uvicorn

# 7) Download model files (Phi-3-mini 4K instruct CPU INT4 variant by default)
# Allow using MISTRAL instead by setting MODEL_CHOICE env var to "mistral"
cd "${WORKDIR}"
MODEL_CHOICE="${MODEL_CHOICE:-phi3}"
MODELDIR="${WORKDIR}/models"
mkdir -p "${MODELDIR}"
echo "Using model choice: ${MODEL_CHOICE}"

if [ "${MODEL_CHOICE}" = "mistral" ]; then
  echo "Downloading Mistral 7B instruct ONNX CPU files (may require HF login/token)..."
  # this will download the specified cpu_and_mobile folder (article example)
  pip install -U "huggingface_hub[cli]" >/dev/null 2>&1 || true
  # Must be logged in for some large files; the user can set HUGGINGFACE_TOKEN
  if [ -n "${HUGGINGFACE_TOKEN:-}" ]; then
    export HUGGINGFACE_HUB_TOKEN="${HUGGINGFACE_TOKEN}"
  fi
  huggingface-cli download microsoft/mistral-7b-instruct-v0.2-ONNX \
    --include "onnx/cpu_and_mobile/mistral-7b-instruct-v0.2-cpu-int4-rtn-block-32-acc-level-4/" \
    --local-dir "${MODELDIR}/mistral-7b-instruct-v0.2-ONNX"
  MODEL_PATH_REL="${MODELDIR}/mistral-7b-instruct-v0.2-ONNX/onnx/cpu_and_mobile/mistral-7b-instruct-v0.2-cpu-int4-rtn-block-32-acc-level-4"
else
  echo "Downloading Phi-3-mini 4K instruct ONNX CPU files (may require HF login/token)..."
  pip install -U "huggingface_hub[cli]" >/dev/null 2>&1 || true
  if [ -n "${HUGGINGFACE_TOKEN:-}" ]; then
    export HUGGINGFACE_HUB_TOKEN="${HUGGINGFACE_TOKEN}"
  fi
  huggingface-cli download microsoft/Phi-3-mini-4k-instruct-onnx \
    --include "cpu_and_mobile/cpu-int4-rtn-block-32-acc-level-4/" \
    --local-dir "${MODELDIR}/Phi-3-mini-4k-instruct-onnx"
  # license file
  huggingface-cli download microsoft/Phi-3-mini-4k-instruct-onnx --include LICENSE --local-dir "${MODELDIR}/Phi-3-mini-4k-instruct-onnx" || true
  MODEL_PATH_REL="${MODELDIR}/Phi-3-mini-4k-instruct-onnx/cpu_and_mobile/cpu-int4-rtn-block-32-acc-level-4"
fi

if [ ! -d "${MODEL_PATH_REL}" ]; then
  echo "Model files not found at ${MODEL_PATH_REL}. Check huggingface-cli output / token / license acceptance."
  echo "You can manually place the ONNX model directory at ${MODEL_PATH_REL}"
  exit 1
fi

# 8) Create server.py (FastAPI) that uses onnxruntime_genai
cat > "${WORKDIR}/server.py" <<'PY'
import os
import time
from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
import onnxruntime_genai as engine

app = FastAPI(title="Local ONNX GenAI API")

MODEL_PATH = os.environ.get("MODEL_PATH", "models/Phi-3-mini-4k-instruct-onnx/cpu_and_mobile/cpu-int4-rtn-block-32-acc-level-4")

class GenerateRequest(BaseModel):
    prompt: str
    max_length: int = 256

@app.on_event("startup")
def load_model():
    global model, tokenizer
    print(f"Loading model from: {MODEL_PATH}")
    model = engine.Model(MODEL_PATH)
    tokenizer = engine.Tokenizer(model)
    print("Model loaded.")

@app.post("/v1/generate")
def generate(req: GenerateRequest):
    try:
        chat_tpl = '<|user|>\n{input}<|end|>\n<|assistant|>'
        prompt = chat_tpl.format(input=req.prompt)
        input_tokens = tokenizer.encode(prompt)
        gen_params = engine.GeneratorParams(model)
        gen_params.set_search_options(max_length=req.max_length)
        gen_params.input_ids = input_tokens
        generator = engine.Generator(model, gen_params)

        # accumulate tokens
        output_parts = []
        tokenizer_stream = tokenizer.create_stream()
        # generate synchronously until done or a safety cap
        safety_iter = 0
        while not generator.is_done():
            generator.compute_logits()
            generator.generate_next_token()
            next_token = generator.get_next_tokens()[0]
            output_parts.append(tokenizer_stream.decode(next_token))
            safety_iter += 1
            if safety_iter > req.max_length + 200:
                # precautionary break
                break
        # cleanup
        del generator
        return {"text": "".join(output_parts)}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

if __name__ == "__main__":
    import uvicorn
    uvicorn.run("server:app", host="0.0.0.0", port=int(os.environ.get("PORT", 8080)), reload=False)
PY

echo "Created server.py"

# 9) Launch server (uvicorn)
echo "Starting uvicorn server on 0.0.0.0:${PORT}..."
# run uvicorn in foreground (so script doesn't exit)
UVICORN_CMD="venv/bin/python -u server.py"
# ensure environment variable MODEL_PATH points to the downloaded model path
export MODEL_PATH="${MODEL_PATH_REL}"
export PORT="${PORT}"
# launch
${UVICORN_CMD}
