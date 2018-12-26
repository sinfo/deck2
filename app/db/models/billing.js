let mongoose = require('mongoose')

let billingSchema = new mongoose.Schema({
  status: {
    pro_forma: { type: Boolean, required: true, default: false },
    invoice: { type: Boolean, required: true, default: false },
    receipt: { type: Boolean, required: true, default: false },
    payed: { type: Boolean, required: true, default: false }
  },
  info: {
    name: { type: String, required: true },
    contact: { type: mongoose.Schema.Types.ObjectId, ref: 'Contact', required: true },
    address: { type: String, required: true },
    tin: { type: String, required: true }, // tax identification number (NIF)
    value: { type: Number, required: true }, // €
    invoiceNumber: { type: String, required: true },
    emission: { type: Date, required: true },
    notes: String
  }
}, {
  toJSON: {
    transform: function (doc, ret) {
      delete ret.__v
    }
  }
})

billingSchema.index({ 'info.emission': -1 })

module.exports = mongoose.model('Billing', billingSchema)
