var mongoose = require('mongoose')

var subscriptionSchema = new mongoose.Schema({
  event: { type: mongoose.Schema.Types.ObjectId, ref: 'Event', required: true },
  member: { type: mongoose.Schema.Types.ObjectId, ref: 'Member', required: true },
  post: { type: mongoose.Schema.Types.ObjectId, ref: 'Communication', required: true },
  subposts: { type: Boolean, default: false }
}, {
  toJSON: {
    transform: function (doc, ret) {
      delete ret.__v
    }
  }
})

module.exports = mongoose.model('Subscription', subscriptionSchema)