'use client'

import DisplayClient from '@/src/components/client/displayClient'
import Metric from '@/src/components/client/metric'
import { useEffect, useState } from 'react'
import config from '../config'
import { Eye } from 'lucide-react'

export default function Home() {
    const [clients, setClients] = useState<Client[]>([])
    const [reconnect, setReconnect] = useState(false)
    const [isConnected, setIsConnected] = useState(false)
    const [participants, setParticipants] = useState(1)

    useEffect(() => {
        const ws = new WebSocket(`${config.url.api_ws}/client/ws/beeswarm`)

        ws.onopen = () => {
            setReconnect(false)
            setIsConnected(true)
        }

        ws.onclose = () => {
            setIsConnected(false)
        }

        ws.onerror = (error) => {
            console.log('WebSocket error:', error)
            setIsConnected(false)
        }

        ws.onmessage = (event) => {
            try {
                const msg = JSON.parse(event.data)
                if (msg.type === 'update') {
                    setParticipants(msg.participants)
                    setClients((prev) => {
                        const existing = prev.find(client => client.name === msg.client.name)
                        if (existing) {
                            return prev.map(client =>
                                client.name === msg.client.name
                                    ? { ...client, ...msg.client }
                                    : client
                            )
                        } else {
                            return [...prev, msg.client]
                        }
                    })
                }

                if (msg.type === 'join') {
                    setParticipants(msg.participants)
                }
            } catch (err) {
                console.error('Invalid message from server:', err)
            }
        }

        return () => {
            ws.close()
        }
    }, [reconnect, clients])

    useEffect(() => {
        setTimeout(() => {
            if (!isConnected) {
                setReconnect(true)
            }
        }, 3000)
    })

    return (
        <div className="min-h-screen bg-black/3 p-16 flex flex-col gap-8">
            <div className='w-full flex justify-between items-center'>
                <h1 className='font-semibold text-2xl h-fit'>BeeSwarm LB Metrics</h1>
                <div className={`flex gap-2 items-center bg-white/5 rounded-lg p-2 px-4 ${config.light}`}>
                    <Eye className='stroke-white/80' />
                    <h1>{participants}</h1>
                </div>
            </div>
            {clients.length ? <Content clients={clients} /> : <h1>No clients connected.</h1>}
        </div>
    )
}

function Content({ clients }: { clients: Client[] }) {
    const totalLoad = {
        ram: Math.ceil(clients.reduce((sum, client) => sum + client.ram.reduce((sum, ram) => sum + ram.load, 0) / client.ram.length * 100, 0) / clients.length),
        cpu: Math.ceil(clients.reduce((sum, client) => sum + client.cpu.reduce((sum, cpu) => sum + cpu.load, 0) / client.cpu.length * 100, 0) / clients.length),
        gpu: Math.ceil(clients.reduce((sum, client) => sum + client.gpu.reduce((sum, gpu) => sum + gpu.load, 0) / client.gpu.length * 100, 0) / clients.length),
    }

    return (
        <div className='space-y-8'>
            <div className="flex w-full gap-4">
                <div className={`flex gap-2 items-center bg-white/5 rounded-lg p-2 px-4 text-lg font-semibold ${config.light}`}>
                    <h1>RAM</h1>
                    <Metric metric={totalLoad.ram} />
                </div>
                <div className={`flex gap-2 items-center bg-white/5 rounded-lg p-2 px-4 text-lg font-semibold ${config.light}`}>
                    <h1>CPU</h1>
                    <Metric metric={totalLoad.cpu} />
                </div>
                <div className={`flex gap-2 items-center bg-white/5 rounded-lg p-2 px-4 text-lg font-semibold ${config.light}`}>
                    <h1>GPU</h1>
                    <Metric metric={totalLoad.gpu} />
                </div>
            </div>
            <h1 className='font-semibold text-2xl h-fit'>Clients</h1>
            <div className='w-full h-full grid gap-4'>
                {clients.map((client, id) => <DisplayClient key={id} client={client} />)}
            </div>
        </div>
    )
}
