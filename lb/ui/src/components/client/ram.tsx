import Metric from './metric'

export default function RAM({ ram }: { ram: RAM }) {
    return (
        <div className='flex gap-2'>
            <h1>{ram.name}</h1>
            <Metric metric={Math.ceil(ram.load * 100)} />
        </div>
    )
}
