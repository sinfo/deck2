let mongoose = require('mongoose')
const config = require('../../../config')

let memberSchema = mongoose.Schema({
  id: { type: String, unique: true },
  name: { type: String, required: true },
  img: String,
  participations: [{
    event: { type: String, required: true },
    role: {
      type: String,
      enum: config.MONGO.ROLES,
      required: true,
      default: config.MONGO.ROLES[0] // minimum
    },
    team: { type: mongoose.Schema.Types.ObjectId, ref: 'Team' }
  }],
  contact: { type: mongoose.Schema.Types.ObjectId, ref: 'Contact', required: true },
  auth: String,
  subscriptions: {
    all: { type: Boolean, default: false },
    mainPosts: [{
      type: mongoose.Schema.Types.ObjectId,
      ref: 'MainPost',
      default: []
    }]
  }
}, {
  toJSON: {
    transform: function (doc, ret) {
      delete ret._id
      delete ret.__v
    }
  }
})

memberSchema.index({ 'participations.event': 1 })

module.exports = mongoose.model('Member', memberSchema)
