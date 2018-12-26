let mongoose = require('mongoose')

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
    package: String // minimum, medium, maximum, exclusive...
  },
  price: { type: Number, required: true },
  curricula: Boolean,
  days: Number
}, {
  toJSON: {
    transform: function (doc, ret) {
      delete ret.__v
    }
  }
})

module.exports = mongoose.model('PackageTemplate', packageTemplateSchema)
