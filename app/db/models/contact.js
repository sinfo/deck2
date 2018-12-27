let mongoose = require('mongoose')

let contactSchema = new mongoose.Schema({
  name: { type: String, required: true },
  phones: [{
    phone: String,
    valid: { type: Boolean, default: true }
  }],
  socials: {
    facebook: String,
    skype: String,
    github: String,
    twitter: String
  },
  mails: {
    sinfo: String,
    ist: String,
    personal: {
      mail: String,
      valid: { type: Boolean, default: true }
    },
    professional: {
      mail: String,
      valid: { type: Boolean, default: true }
    }
  }
}, {
  toJSON: {
    transform: function (doc, ret) {
      delete ret.__v
    }
  }
})

module.exports = mongoose.model('Contact', contactSchema)
