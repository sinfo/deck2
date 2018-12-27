let mongoose = require('mongoose')
const config = require('@config')

let speakerSchema = new mongoose.Schema({
  name: { type: String, required: true },
  contacts: {
    type: [{ type: mongoose.Schema.Types.ObjectId, ref: 'Contact' }],
    default: [],
    required: true
  },
  title: { type: String, default: '' },
  description: { type: String, default: '' },
  information: { type: String, default: '' },
  img: String,
  participations: [{
    event: { type: mongoose.Schema.Types.ObjectId, ref: 'Event' },
    member: { type: String, required: true },
    status: {
      type: String,
      enum: config.MONGO.PARTICIPATION_STATUS,
      required: true,
      default: config.MONGO.PARTICIPATION_STATUS[0] // suggested
    },
    posts: {
      type: [{ type: mongoose.Schema.Types.ObjectId, ref: 'Communication' }],
      default: [],
      required: true
    },
    imgs: {
      speaker: {
        type: [{
          img: String,
          public: { type: Boolean, default: false }
        }],
        default: [],
        required: true
      },
      company: {
        type: [{
          img: String,
          public: { type: Boolean, default: false }
        }],
        default: [],
        required: true
      }
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
