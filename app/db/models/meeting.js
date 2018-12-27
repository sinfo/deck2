let mongoose = require('mongoose')
const config = require('../../../config')

let meetingSchema = new mongoose.Schema({
  begin: { type: Date, required: true },
  end: { type: Date },
  place: String,
  kind: {
    type: String,
    enum: config.MONGO.EVENT_TYPES,
    required: true
  },
  participants: [{ type: mongoose.Schema.Types.ObjectId, ref: 'Contact', required: true }]
}, {
  toJSON: {
    transform: function (doc, ret) {
      delete ret.__v
    }
  }
})

meetingSchema.index({ begin: -1 })

module.exports = mongoose.model('Meeting', meetingSchema)
