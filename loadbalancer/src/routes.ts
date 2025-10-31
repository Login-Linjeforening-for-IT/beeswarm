import type { FastifyInstance, FastifyPluginOptions } from "fastify"
import getIndex from './handlers/index/get.ts'
import getLink from './handlers/links/get.ts'
import putLink from './handlers/links/put.ts'
import postLink from './handlers/links/post.ts'

export default async function apiRoutes(fastify: FastifyInstance, _: FastifyPluginOptions) {
    // index
    fastify.get("/", getIndex)

    // links
    fastify.get("/link/:id", getLink)
    fastify.put("/link/:id", putLink)
    fastify.post("/link/:id", postLink)
}
