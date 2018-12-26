let mongoose = require('mongoose')

let eventSchema = new mongoose.Schema({
  name: { type: String, required: true },
  begin: { type: Date, required: true },
  end: { type: Date, required: true },
  days: [{
    day: Number,
    theme: String
  }]
})

eventSchema.index({ begin: -1 })

module.exports = mongoose.model('Event', eventSchema)
