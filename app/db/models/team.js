let mongoose = require('mongoose')

let teamSchema = new mongoose.Schema({
  event: { type: mongoose.Schema.Types.ObjectId, ref: 'Event' },
  name: { type: String, required: true }
}, {
  toJSON: {
    transform: function (doc, ret) {
      delete ret.__v
    }
  }
})

teamSchema.index({ event: 1, name: 1 })

module.exports = mongoose.model('Team', teamSchema)
