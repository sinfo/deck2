let mongoose = require('mongoose')

let memberSchema = mongoose.Schema({
  id: { type: String, unique: true },
  name: String,
  img: String,
  participations: [{
    event: String,
    role: String
  }],
  socials: {
    facebook: String,
    skype: String,
    github: String,
    twitter: String
  },
  phone: String,
  mails: {
    sinfo: String,
    ist: String,
    personal: String
  },
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
