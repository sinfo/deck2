let mongoose = require('mongoose')

let companySchema = new mongoose.Schema({
  name: { type: String, required: true },
  description: String,
  img: String,
  site: String,
  contacts: [{ type: mongoose.Schema.Types.ObjectId, ref: 'Contact', required: true }],
  history: String,
  participations: [{
    event: { type: mongoose.Schema.Types.ObjectId, ref: 'Event', required: true },
    member: { type: String, required: true },
    status: { type: String, required: true },
    billing: { type: mongoose.Schema.Types.ObjectId, ref: 'Billing' },
    package: {
      advertising: {
        items: {
          type: [{
            item: { type: mongoose.Schema.Types.ObjectId, ref: 'AdvertisingItem' },
            size: String
          }],
          required: true,
          default: []
        },
        package: String // minimum, medium, maximum, exclusive...
      },
      price: { type: Number, required: true }, // €
      curricula: Boolean,
      days: Number,
      confirmation: { type: Date, required: true }
    }
  }]
}, {
  toJSON: {
    transform: function (doc, ret) {
      delete ret.__v
    }
  }
})

module.exports = mongoose.model('Company', companySchema)
