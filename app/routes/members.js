const Joi = require('joi')

module.exports = [
  {
    method: 'GET',
    path: '/auth/{memberId}',
    config: {
      tags: ['api'],
      description: 'Check token validation',
      handler: async (request, h) => {
        try {
          const jwt = await request.server.methods.jwt.generate('26-sinfo', request.params.memberId)
          return jwt
        } catch (err) {
          console.error('jwt', err)
        }
      },
      validate: {
        params: {
          memberId: Joi.string()
            .required().min(1).max(50)
            .description('Company identifier')
        }
      }
    }
  },
  {
    method: 'GET',
    path: '/auth',
    config: {
      auth: 'MEMBER',
      tags: ['api'],
      description: 'Check token validation',
      handler: async (request, h) => {
        return request.auth.credentials
      },
      validate: {
        headers: Joi.object({
          'Authorization': Joi.string()
        }).unknown()
      }
    }
  }
]
