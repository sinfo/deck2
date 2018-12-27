let mongoose = require('mongoose')

let advertisingItemSchema = new mongoose.Schema({
  name: { type: String, required: true, unique: true },
  description: String,
  img: String,
  price: Number
}, {
  toJSON: {
    transform: function (doc, ret) {
      delete ret.__v
    }
  }
})

module.exports = mongoose.model('AdvertisingItem', advertisingItemSchema)
