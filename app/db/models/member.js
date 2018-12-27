let mongoose = require('mongoose')
const config = require('../../../config')

let memberSchema = mongoose.Schema({
  name: { type: String, required: true },
  img: String,
  participations: [{
    event: { type: mongoose.Schema.Types.ObjectId, ref: 'Event', required: true },
    role: {
      type: String,
      enum: config.MONGO.ROLES,
      required: true,
      default: config.MONGO.ROLES[0] // minimum
    },
    team: { type: mongoose.Schema.Types.ObjectId, ref: 'Team' }
  }],
  contact: { type: mongoose.Schema.Types.ObjectId, ref: 'Contact', required: true },
  auth: String
}, {
  toJSON: {
    transform: function (doc, ret) {
      delete ret._id
      delete ret.__v
    }
  }
})

module.exports = mongoose.model('Member', memberSchema)
