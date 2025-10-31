export default function Metric({ metric }: { metric: number }) {
    const color = metric < 50 ? 'text-green-500' : metric < 75 ? 'text-yellow-500' : 'text-red-500' 

    return (
        <h1 className={color}>{metric}%</h1>
    )
}
