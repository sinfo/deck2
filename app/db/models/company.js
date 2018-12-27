let mongoose = require('mongoose')
const config = require('../../../config')

let companySchema = new mongoose.Schema({
  name: { type: String, required: true },
  description: String,
  img: String,
  site: String,
  contacts: [{
    type: { type: mongoose.Schema.Types.ObjectId, ref: 'Contact', required: true },
    default: [],
    required: true
  }],
  posts: [{
    type: { type: mongoose.Schema.Types.ObjectId, ref: 'MainPost', required: true },
    default: [],
    required: true
  }],
  participations: [{
    type: [{
      event: { type: mongoose.Schema.Types.ObjectId, ref: 'Event', required: true },
      member: { type: String, required: true },
      status: {
        type: String,
        enum: config.MONGO.PARTICIPATION_STATUS,
        required: true,
        default: config.MONGO.PARTICIPATION_STATUS[0] // suggested
      },
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
          package: {
            type: String,
            enum: config.MONGO.ADVERTISING_PACKAGE,
            required: true,
            default: config.MONGO.ADVERTISING_PACKAGE[0] // min
          } // minimum, medium, maximum, exclusive...
        },
        price: { type: Number, required: true }, // €
        curricula: Boolean,
        days: Number,
        confirmation: { type: Date, required: true },
        notes: String
      }
    }],
    default: []
  }]
}, {
  toJSON: {
    transform: function (doc, ret) {
      delete ret.__v
    }
  }
})

module.exports = mongoose.model('Company', companySchema)
