const SERVER_URL = "http://localhost:8081/v1/completions"

async function askLlama(prompt) {
    const reqdata = {
        "model": "gpt-5-mini",
        "messages": [
            {
                "role": "user",
                "content": prompt
            }
        ],
        "max_tokens": 512,
        "temperature": 0.7
    }
    console.log("sending", reqdata)
    const response = await fetch(SERVER_URL, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(reqdata)
    })
    const data = await response.json()
    return data.completion
}

(async () => {
    const answer = await askLlama("Write a short poem about autumn.")
    console.log(answer)
})()
