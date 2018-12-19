const config = require('./config')
const Hapi = require('hapi')
const logger = require('@sinfo/logger').getLogger()

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

// Start the server
async function start () {
  try {
    config.validate()
    logger.debug('starting')
    await server.start()
  } catch (err) {
    logger.error(err)
    process.exit(1)
  }
};

module.exports.start = start
module.exports.server = server
