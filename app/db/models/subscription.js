var mongoose = require('mongoose')

var subscriptionSchema = new mongoose.Schema({
  event: { type: mongoose.Schema.Types.ObjectId, ref: 'Event', required: true },
  member: { type: mongoose.Schema.Types.ObjectId, ref: 'Member', required: true },
  post: { type: mongoose.Schema.Types.ObjectId, ref: 'MainPost', required: true },
  subposts: { type: Boolean, default: false }
})

module.exports = mongoose.model('Subscription', subscriptionSchema)
