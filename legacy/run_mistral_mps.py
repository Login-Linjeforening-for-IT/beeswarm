from fastapi import FastAPI
from pydantic import BaseModel
from mistral_inference.transformer import Transformer
from mistral_inference.generate import generate
from mistral_common.tokens.tokenizers.mistral import MistralTokenizer
from mistral_common.protocol.instruct.messages import UserMessage
from mistral_common.protocol.instruct.request import ChatCompletionRequest
import torch
import psutil
import os

app = FastAPI(title="Mistral 7B Instruct (Metal)", version="1.0")

# ---------- Device setup ----------
device = "mps" if torch.backends.mps.is_available() else "cpu"
print(f"🧠 Using device: {device}")

# ---------- Memory allocation control ----------
def set_memory_limit(target_gb: int | None):
    total = psutil.virtual_memory().total / (1024**3)
    if target_gb and target_gb < total:
        os.environ["PYTORCH_MPS_HIGH_WATERMARK_RATIO"] = str(target_gb / total)
        print(f"🔧 Set memory limit: {target_gb} GB of {total:.1f} GB total")
    else:
        print(f"🧩 Using all available memory ({total:.1f} GB)")

# Change here to 24, 32, 64 or None (for max)
TARGET_MEMORY_GB = 32
set_memory_limit(TARGET_MEMORY_GB)

# ---------- Load model ----------
model_path = "./models/mistral"
print("🔄 Loading tokenizer and model…")
tokenizer = MistralTokenizer.from_file(f"{model_path}/tokenizer.model.v3")
model = Transformer.from_folder(model_path)

# Move to device if possible (MPS or CPU)
if hasattr(model, "to"):
    model = model.to(device)
print("✅ Model loaded and ready.")

# ---------- Request schema ----------
class PromptRequest(BaseModel):
    prompt: str
    max_tokens: int = 128
    temperature: float = 0.7

# ---------- Root endpoint ----------
@app.get("/")
def home():
    return {"status": "ok", "device": device, "message": "Mistral 7B Instruct API (Metal) is running!"}

# ---------- Generation endpoint ----------
@app.post("/generate")
def generate_text(req: PromptRequest):
    try:
        completion_request = ChatCompletionRequest(messages=[UserMessage(content=req.prompt)])
        tokens = tokenizer.encode_chat_completion(completion_request).tokens

        # Generate output
        out_tokens, _ = generate(
            [tokens],
            model,
            max_tokens=req.max_tokens,
            temperature=req.temperature,
            eos_id=tokenizer.instruct_tokenizer.tokenizer.eos_id,
        )

        text = tokenizer.instruct_tokenizer.tokenizer.decode(out_tokens[0])
        return {"prompt": req.prompt, "response": text}
    except Exception as e:
        return {"error": str(e)}
