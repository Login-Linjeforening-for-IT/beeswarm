import metrics from '#utils/metrics.ts'
import { beeswarm } from './handleMessage'
import { WebSocket as WS } from 'ws'

export default async function sendMetrics(id: string, sender: WS) {
    const clients = beeswarm.get(id)
    if (!clients) {
        return
    }

    const payload = JSON.stringify({
        type: 'update',
        metrics: await metrics(),
        timestamp: new Date().toISOString(),
        participants: clients.size
    })

    for (const client of clients) {
        if (client !== sender && client.readyState === WS.OPEN) {
            client.send(payload)
        }
    }
}
