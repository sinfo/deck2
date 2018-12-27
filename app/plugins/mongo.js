const mongoose = require('mongoose')
const logger = require('@sinfo/logger').getLogger()
const config = require('../../config')

const MONGO_URL = process.env.NODE_ENV === 'test'
  ? `mongodb://localhost:${config.MONGO.PORT}/${config.MONGO.TEST}`
  : `mongodb://localhost:${config.MONGO.PORT}/${config.MONGO.DB}`

module.exports = {
  name: 'mongo',
  version: '1.0.0',
  register: async (server, options) => {
    mongoose.connect(MONGO_URL,
      {
        useNewUrlParser: true,
        reconnectTries: Number.MAX_VALUE,
        reconnectInterval: 500,
        useCreateIndex: true
      }
    )

    let db = mongoose.connection

    db.on('connecting', () => {
      logger.debug(`Trying to connect the daemon`)
    })

    db.on('disconnected', () => {
      logger.error(`Disconnected from the mongo daemon`)
    })

    db.on('error', (err) => {
      logger.error(`Connection error: ${err.message}`)
    })

    db.on('reconnected', () => {
      logger.info(`Reconnected to ${MONGO_URL}`)
    })

    if (process.env.NODE_ENV !== 'test') {
      db.on('open', function () {
        logger.info(`Connected to ${MONGO_URL}`)
      })
    }
  }
}
