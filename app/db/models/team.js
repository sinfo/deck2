let mongoose = require('mongoose')

let teamSchema = new mongoose.Schema({
  event: { type: mongoose.Schema.Types.ObjectId, ref: 'Event', required: true },
  name: { type: String, required: true }
}, {
  toJSON: {
    transform: function (doc, ret) {
      delete ret.__v
    }
  }
})

module.exports = mongoose.model('Team', teamSchema)
