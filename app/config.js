const getLogger = require('@sinfo/logger').getLogger

const config = {
  HOST: process.env.DECK_HOST || 'localhost',
  PORT: process.env.DECK_PORT || 8080,

  DECK_PATH: process.env.NODE_ENV === 'production'
    ? process.env.DECK_PATH
    : 'localhost:8888',

  MONGO: {
    DB: process.env.DECK_MONGO_DB || 'deck',
    TEST: process.env.DECK_MONGO_DB_TEST || 'deck_test',
    PORT: process.env.DECK_MONGO_PORT || 27017
  }
}

const logger = process.env.DECK_LOGENTRIES_TOKEN &&
  config.MAILGUN.API_KEY &&
  process.env.NODE_ENV === 'production'
  ? getLogger(
    process.env.DECK_LOGENTRIES_TOKEN,
    config.MAILGUN.API_KEY,
    'Deck'
  )
  : getLogger()

function validate () {
  if (process.env.NODE_ENV === 'production') {
    logger.warn('Running in production mode')
  }
}

module.exports.config = config
module.exports.validate = validate
