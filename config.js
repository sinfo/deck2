const { getLogger } = require('@sinfo/logger')
const fs = require('fs')
const { generateKeyPairSync } = require('crypto')

const config = {
  HOST: process.env.DECK_HOST || 'localhost',
  PORT: process.env.DECK_PORT || 8080,

  ENV: process.env.NODE_ENV | 'dev',

  DECK_PATH: process.env.NODE_ENV === 'production'
    ? process.env.DECK_PATH
    : 'localhost:8080',

  CORS: process.env.NODE_ENV === 'production'
    ? ['*sinfo.org']
    : ['*'],

  MONGO: {
    DB: process.env.DECK_MONGO_DB || 'deck2',
    TEST: process.env.DECK_MONGO_DB_TEST || 'deck2_test',
    PORT: process.env.DECK_MONGO_PORT || 27017,

    // roles must be sorted by priviledge level
    ROLES: ['MEMBER', 'TEAM_LEADER', 'COORDINATOR', 'ADMIN'],
    EVENT_TYPES: ['TEAM', 'SINFO', 'COMPANY'],
    PARTICIPATION_STATUS: [
      'SUGGESTED', 'SELECTED', 'APPROVED',
      'CONTACTED', 'IN_CONVERSATIONS', 'ACCEPTED',
      'REJECTED', 'GIVEN_UP', 'ANNOUNCED'
    ],
    ADVERTISING_PACKAGE: ['min', 'med', 'max', 'exclusive', 'partnership']
  },

  GOOGLE: process.env.DECK_GOOGLE ? JSON.parse(process.env.DECK_GOOGLE) : undefined,

  JWT: {
    PRIVATE_PATH: './keys/jwtRS256.key',
    PUBLIC_PATH: './keys/jwtRS256.key.pub',
    TTL: 60 * 60 * 24 * 7 // time to live in seconds (1 week)
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

function generateKeys () {
  const { publicKey, privateKey } = generateKeyPairSync('rsa', {
    modulusLength: 4096,
    publicKeyEncoding: {
      type: 'pkcs1',
      format: 'pem'
    },
    privateKeyEncoding: {
      type: 'pkcs1',
      format: 'pem'
    }
  })

  try {
    fs.writeFileSync(config.JWT.PRIVATE_PATH, privateKey)
    fs.writeFileSync(config.JWT.PUBLIC_PATH, publicKey)
  } catch (err) {
    logger.error('Couldn\'t write keys to file.')
    process.exit(1)
  }

  config.JWT.PRIVATE = privateKey
  config.JWT.PUBLIC = publicKey
}

function validate () {
  if (config.ENV === 'production') {
    logger.warn('Running in production mode')
  }

  if (config.GOOGLE === undefined) {
    logger.error(`Env var of GOOGLE not defined`)
    process.exit(1)
  }

  for (let key of Object.keys(config.GOOGLE.web)) {
    if (config.GOOGLE.web[key] === undefined) {
      logger.error(`Env var of GOOGLE.web.${key} not defined`)
      process.exit(1)
    }
  }

  return new Promise((resolve, reject) => {
    // Check if the file exists in the current directory.
    fs.access(config.JWT.PRIVATE_PATH, fs.constants.R_OK, (err) => {
      if (err) {
        logger.info(`${config.JWT.PRIVATE_PATH} does not exist. Generating key pair...`)
        generateKeys()
        return resolve()
      }

      // private key exists
      // on to reading the public key

      fs.access(config.JWT.PUBLIC_PATH, fs.constants.R_OK, (err) => {
        if (err) {
          logger.info(`${config.JWT.PUBLIC_PATH} does not exist. Generating key pair...`)
          generateKeys()
          return resolve()
        }

        // key pair exists
        config.JWT.PRIVATE = fs.readFileSync(config.JWT.PRIVATE_PATH)
        config.JWT.PUBLIC = fs.readFileSync(config.JWT.PUBLIC_PATH)

        return resolve()
      })
    })
  })
}

module.exports = config
module.exports.validate = validate
