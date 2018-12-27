let mongoose = require('mongoose')

let notificationSchema = new mongoose.Schema({
  post: { type: mongoose.Schema.Types.ObjectId, ref: 'Post', required: true },
  member: { type: mongoose.Schema.Types.ObjectId, ref: 'Member', required: true },
  description: String,
  targets: {
    type: [{
      member: { type: mongoose.Schema.Types.ObjectId, ref: 'Member', required: true },
      seen: { type: Boolean, default: false, required: true }
    }],
    required: true
  },
  posted: { type: Date, required: true }
}, {
  toJSON: {
    transform: function (doc, ret) {
      delete ret.__v
    }
  }
})

notificationSchema.index({ posted: -1 })

module.exports = mongoose.model('Notification', notificationSchema)
