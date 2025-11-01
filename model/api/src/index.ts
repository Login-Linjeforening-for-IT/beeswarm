import WebSocket from 'ws'
import sendMetrics from '#utils/sendMetrics.ts'
import config from '#constants'

if (!config.ws_api) {
    console.error('Missing WS API')
    process.exit(1)
}

const MAX_BACKOFF = 30000
let backoff = 1000
let interval: NodeJS.Timeout | null = null
let connecting = false
let socket: WebSocket | null = null

function connect() {
    if (socket || connecting) return

    console.log(`Connecting to ${config.ws_api} ...`)

    socket = new WebSocket(`${config.ws_api}/client/ws/beeswarm`)

    socket.on('open', () => {
        console.log('Connected to WebSocket server.')
        backoff = 1000

        interval = setInterval(() => {
            if (socket?.readyState === WebSocket.OPEN) {
                sendMetrics(socket)
            }
        }, 1000)
    })

    socket.on('message', (rawMessage) => {
        try {
            const msg = JSON.parse(rawMessage.toString())
            if (msg.type !== 'join' && msg.type !== 'update') {
                console.log('Received:', msg)
            }

            if (msg.type === 'prompt') {
                console.log('Received prompt:', msg)
            }
        } catch (err) {
            console.error('Invalid message format:', err)
        }
    })

    socket.on('close', () => {
        console.warn('WebSocket connection closed.')
        if (interval) {
            clearInterval(interval)
        }

        socket = null
        retryConnection()
    })

    socket.on('error', (err) => {
        if (JSON.stringify(err).includes('ECONNREFUSED')) {
            return console.error('Unable to reach BeeSwarm.')
        }

        console.error('WebSocket error:', err)
        socket?.close()
    })
}

function retryConnection() {
    console.log(`Reconnecting in ${backoff / 1000}s...`)
    setTimeout(connect, backoff)
    backoff = Math.min(backoff * 2, MAX_BACKOFF)
}

connect()
