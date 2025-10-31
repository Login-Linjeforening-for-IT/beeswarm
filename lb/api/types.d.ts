type SQLParamType = (string | number | null | boolean | string[] | Date | Buffer)[]

type Client = {
    name: string
    ram: RAM[]
    cpu: CPU[]
    gpu: GPU[]
}

type RAM = {
    name: string
    load: number
}

type CPU = {
    name: string
    load: number
}

type GPU = {
    name: string
    load: number
}
