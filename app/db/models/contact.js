let mongoose = require('mongoose')

let contactSchema = new mongoose.Schema({
  name: { type: String, required: true },
  phone: [ String ],
  socials: {
    facebook: String,
    skype: String,
    github: String,
    twitter: String
  },
  mails: {
    sinfo: String,
    ist: String,
    personal: String,
    professional: String
  }
}, {
  toJSON: {
    transform: function (doc, ret) {
      delete ret.__v
    }
  }
})

module.exports = mongoose.model('Contact', contactSchema)
