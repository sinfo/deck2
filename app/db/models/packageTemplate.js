let mongoose = require('mongoose')
const config = require('@config')

let packageTemplateSchema = new mongoose.Schema({
  name: { type: String, required: true },
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
  price: { type: Number, required: true },
  curricula: { type: Boolean, required: true, default: false },
  days: { type: Number, required: true }
}, {
  toJSON: {
    transform: function (doc, ret) {
      delete ret.__v
    }
  }
})

module.exports = mongoose.model('PackageTemplate', packageTemplateSchema)
