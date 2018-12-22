let mongoose = require('mongoose')
let Post = require('./post')

let MainPost = Post.discriminator(
  'MainPost',
  new mongoose.Schema({
    kind: { type: String, required: true },
    status: {
      type: String,
      enum: ['APPROVED', 'REVIEWED', 'PENDING'],
      required: true,
      default: 'PENDING'
    }
  }, { discriminatorKey: 'level' })
)

module.exports = MainPost
