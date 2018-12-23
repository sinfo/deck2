let mongoose = require('mongoose')

let memberSchema = mongoose.Schema({
  id: { type: String, unique: true },
  name: String,
  img: String,
  participations: [{
    event: { type: String, required: true },
    role: { type: mongoose.Schema.Types.ObjectId, ref: 'Role', required: true },
    team: { type: mongoose.Schema.Types.ObjectId, ref: 'Team' }
  }],
  contact: { type: mongoose.Schema.Types.ObjectId, ref: 'Contact' },
  auth: String,
  subscriptions: {
    all: Boolean,
    mainPosts: [{ type: mongoose.Schema.Types.ObjectId, ref: 'MainPost' }]
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
