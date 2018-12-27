let mongoose = require('mongoose')
let Post = require('./post')
const config = require('@config')

let Communication = Post.discriminator(
  'Communication',
  new mongoose.Schema({
    kind: {
      type: String,
      enum: config.MONGO.POST_KIND,
      required: true,
      default: config.MONGO.POST_KIND[0]
    },
    contact: { type: mongoose.Schema.Types.ObjectId, ref: 'Contact' },
    meeting: { type: mongoose.Schema.Types.ObjectId, ref: 'Meeting' },
    status: {
      type: String,
      enum: config.MONGO.POST_STATUS,
      required: true,
      default: config.MONGO.POST_STATUS[0]
    }
  }, { discriminatorKey: 'level' })
)

module.exports = Communication
