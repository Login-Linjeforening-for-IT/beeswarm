import WebSocket from 'ws'
import sendMetrics from '#utils/sendMetrics.ts'
import config from '#constants'

if (!config.ws_api) {
    process.exit('Missing WS API')
}

const socket = new WebSocket(config.ws_api)

socket.on('open', () => {
    console.log('Connected to WebSocket server.')
})

const interval = setInterval(() => {
    sendMetrics(socket)
}, 1000)

socket.on('message', (rawMessage) => {
    try {
        const msg = JSON.parse(rawMessage.toString())
        console.log('Received:', msg)

        if (msg.type === 'prompt') {
            console.log("recieved prompt", msg)
        }
    } catch (err) {
        console.error('Invalid message format:', err)
    }
})

socket.on('close', () => {
    console.log('WebSocket connection closed.')
    clearInterval(interval)
})

socket.on('error', (err) => {
    console.error('WebSocket error:', err)
})
