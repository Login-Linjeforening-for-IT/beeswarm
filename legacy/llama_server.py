from flask import Flask, request, jsonify
import requests

app = Flask(__name__)

LLAMA_SERVER_URL = 'http://127.0.0.1:8080/v1/chat/completions'

@app.route('/', methods=['POST'])
def predict():
    data = request.get_json()
    prompt = data.get('input', '')

    payload = {
        "model": "mistral-7b-instruct",  # or whatever the server expects
        "messages": [
            {"role": "user", "content": prompt}
        ],
        "max_tokens": 512,
        "temperature": 0.8
    }

    response = requests.post(LLAMA_SERVER_URL, json=payload)
    if response.status_code == 200:
        result = response.json()
        # Assuming OpenAI style response:
        text = result["choices"][0]["message"]["content"]
        return jsonify({"output": text.strip()})
    else:
        return jsonify({"error": response.text}), response.status_code

if __name__ == '__main__':
    app.run(port=8081)
