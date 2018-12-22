let mongoose = require('mongoose')

let eventSchema = new mongoose.Schema({
  id: { type: String, required: true, unique: true },
  name: { type: String, required: true },
  begin: { type: Date, required: true },
  end: { type: Date, required: true }
})

eventSchema.index({ id: 1, begin: -1 })

module.exports = mongoose.model('Event', eventSchema)
