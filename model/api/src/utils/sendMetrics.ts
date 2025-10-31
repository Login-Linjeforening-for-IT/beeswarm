import metrics from '#utils/metrics.ts'
import { WebSocket as WS } from 'ws'

export default async function sendMetrics(sender: WS) {
    const payload = JSON.stringify({
        type: 'update',
        metrics: await metrics(),
        timestamp: new Date().toISOString()
    })

    sender.send(payload)
}
