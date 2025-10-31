import packagejson from '../package.json'

const config = {
    url: {
        // api: 'http://localhost:8080/api',
        api: 'https://api.beeswarm.login.no/api',
        // api_ws: 'ws://localhost:8080/api',
        api_ws: 'wss://api.beeswarm.login.no/api',
    },
    version: packagejson.version
}

export default config
