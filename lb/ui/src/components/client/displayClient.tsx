'use client'

import { useState } from 'react'
import CPU from './cpu'
import GPU from './gpu'
import RAM from './ram'
import Metric from './metric'
import config from '@/src/config'

export default function DisplayClient({ client }: { client: Client }) {
    const [open, setOpen] = useState(false)

    return (
        <div className={`grid gap-4 cursor-pointer bg-white/5 rounded-lg p-4 ${config.light}`} onClick={() => setOpen(prev => !prev)}>
            <Open client={client} open={open} />
            <Closed client={client} open={open} />
        </div>
    )
}

function Open({ client, open }: { client: Client, open: boolean }) {
    if (!open) {
        return
    }

    return (
        <div className='space-y-2'>
            <h1 className='font-semibold text-lg'>{client.name}</h1>
            <div className='grid grid-cols-3 gap-4'>
                <div className='space-y-2'>
                    <h1 className='text-lg font-semibold'>RAM</h1>
                    <h1>{client.ram.map((ram, id) => <RAM key={id} ram={ram} />)}</h1>
                </div>
                <div className='space-y-2'>
                    <h1 className='text-lg font-semibold'>CPU</h1>
                    <h1>{client.cpu.map((cpu, id) => <CPU key={id} cpu={cpu} />)}</h1>
                </div>
                <div className='space-y-2'>
                    <h1 className='text-lg font-semibold'>GPU</h1>
                    <h1>{client.gpu.map((gpu, id) => <GPU key={id} gpu={gpu} />)}</h1>
                </div>
            </div>
        </div>
    )
}

function Closed({ client, open }: { client: Client, open: boolean }) {
    const stats = {
        ram: Math.ceil(client.ram.reduce((sum, ram) => sum + ram.load, 0) / client.ram.length * 100),
        cpu: Math.ceil(client.cpu.reduce((sum, cpu) => sum + cpu.load, 0) / client.cpu.length * 100),
        gpu: Math.ceil(client.gpu.reduce((sum, gpu) => sum + gpu.load, 0) / client.gpu.length * 100),
    }

    if (open) {
        return
    }

    return (
        <div className='grid grid-cols-4 gap-4'>
            <h1 className='font-semibold text-lg'>{client.name}</h1>
            <div className='flex gap-2 font-semibold'>
                <h1>RAM</h1>
                <Metric metric={stats.ram} />
            </div>
            <div className='flex gap-2 font-semibold'>
                <h1>CPU</h1>
                <Metric metric={stats.cpu} />
            </div>
            <div className='flex gap-2 font-semibold'>
                <h1>GPU</h1>
                <Metric metric={stats.gpu} />
            </div>
        </div>
    )
}
