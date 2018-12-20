const config = require('../../config')
const jwt = require('jsonwebtoken')

async function generate (edition, member) {
  return jwt.sign(
    {
      edition: edition,
      member: member
    },
    config.JWT.PRIVATE,
    {
      algorithm: 'RS256',
      expiresIn: Math.floor(Date.now() / 1000) + config.JWT.TTL
    }
  )
}

async function verify (token) {
  try {
    return jwt.verify(token, config.JWT.PUBLIC)
  } catch (err) {
    return null
  }
}

module.exports = {
  name: 'jwt',
  version: '1.0.0',
  register: async server => {
    // TODO google oauth to generate JWT tokens
    server.method('jwt.generate', generate)
    server.method('jwt.verify', verify)

    server.auth.strategy('member', 'bearer-access-token', {
      validate: async (request, token, h) => {
        try {
          let decoded = await verify(token)

          return decoded
            ? { isValid: true, credentials: decoded, artifacts: token }
            : { isValid: false, credentials: token, artifacts: token }
        } catch (err) {
          return { isValid: false, credentials: token, artifacts: token }
        }
      }
    })
  }
}
