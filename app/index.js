// require paths explicit on package.json under "_moduleAliases"
require('module-alias/register')

const config = require('@config')
const logger = require('@sinfo/logger').getLogger()
const Hapi = require('hapi')
const Inert = require('inert')
const Vision = require('vision')
const hapiRouter = require('hapi-router')
const HapiSwagger = require('hapi-swagger')
const Pack = require('../package')

// Create a server with a host and port
const server = Hapi.server({
  host: config.HOST,
  port: config.PORT,
  routes: {
    cors: {
      origin: config.CORS
    }
  }
})

async function register () {
  await server.register(require('./plugins'))
  await server.register([
    {
      plugin: hapiRouter,
      options: {
        routes: './app/routes/*.js'
      }
    },
    Inert,
    Vision,
    {
      plugin: HapiSwagger,
      options: {
        schemes: [ process.env.NODE_ENV === 'production' ? 'https' : 'http' ],
        host: config.DECK_PATH,
        cors: true,
        info: {
          title: `${Pack.name} API documentation`,
          version: Pack.version
        }
      }
    }
  ])
}

// Start the server
async function start () {
  try {
    await config.validate()
    await register()
    await server.start()
  } catch (err) {
    logger.error(err)
    process.exit(1)
  }
};

module.exports.start = start
module.exports.register = register
module.exports.server = server
