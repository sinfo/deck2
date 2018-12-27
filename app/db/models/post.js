let mongoose = require('mongoose')

let postSchema = mongoose.Schema({
  event: { type: mongoose.Schema.Types.ObjectId, ref: 'Event', required: true },
  member: { type: String, required: true },
  text: { type: String, required: true },
  posts: {
    type: [{ type: mongoose.Schema.Types.ObjectId, ref: 'Post' }],
    default: [],
    required: true
  },
  posted: { type: Date, default: Date.now },
  updated: { type: Date, default: Date.now }
}, {
  discriminatorKey: 'level',
  toJSON: {
    transform: function (doc, ret) {
      delete ret.__v
    }
  }
})

module.exports = mongoose.model('Post', postSchema)
