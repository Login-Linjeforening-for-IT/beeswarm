import Metric from './metric'

export default function GPU({ gpu }: { gpu: GPU }) {
    return (
        <div className='flex gap-2'>
            <h1>{gpu.name}</h1>
            <Metric metric={Math.ceil(gpu.load * 100)} />
        </div>
    )
}
