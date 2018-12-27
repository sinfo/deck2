let mongoose = require('mongoose')
const config = require('../../../config')

let speakerSchema = new mongoose.Schema({
  name: { type: String, required: true },
  contacts: [{
    type: { type: mongoose.Schema.Types.ObjectId, ref: 'Contact', required: true },
    default: [],
    required: true
  }],
  title: { type: String, default: '' },
  description: { type: String, default: '' },
  information: { type: String, default: '' },
  img: String,
  posts: [{
    type: { type: mongoose.Schema.Types.ObjectId, ref: 'MainPost', required: true },
    default: [],
    required: true
  }],
  participations: [{
    event: { type: mongoose.Schema.Types.ObjectId, ref: 'Event', required: true },
    member: { type: String, required: true },
    status: {
      type: String,
      enum: config.MONGO.PARTICIPATION_STATUS,
      required: true,
      default: config.MONGO.PARTICIPATION_STATUS[0] // suggested
    },
    imgs: {
      speaker: [{
        type: {
          img: String,
          public: { type: Boolean, default: false }
        },
        default: [],
        required: true
      }],
      company: [{
        type: {
          img: String,
          public: { type: Boolean, default: false }
        },
        default: [],
        required: true
      }]
    },
    feedback: String
  }]
}, {
  toJSON: {
    transform: function (doc, ret) {
      delete ret.__v
    }
  }
})

module.exports = mongoose.model('Speaker', speakerSchema)
