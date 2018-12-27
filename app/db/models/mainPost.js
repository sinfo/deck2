let mongoose = require('mongoose')
let Post = require('./post')
const config = require('@config')

let MainPost = Post.discriminator(
  'MainPost',
  new mongoose.Schema({
    kind: { type: String, required: true },
    status: {
      type: String,
      enum: config.POST_STATUS,
      required: true,
      default: config.POST_STATUS[0]
    }
  }, { discriminatorKey: 'level' })
)

module.exports = MainPost
