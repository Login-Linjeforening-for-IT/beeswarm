import Metric from './metric'

export default function CPU({ cpu }: { cpu: CPU }) {
    return (
        <div className='flex gap-2'>
            <h1>{cpu.name}</h1>
            <Metric metric={Math.ceil(cpu.load * 100)} />
        </div>
    )
}
