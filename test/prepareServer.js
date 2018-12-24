const { before, after } = require('mocha')
const mongoose = require('mongoose')
const { server, start } = require('../app')

async function cleanUp () {
  const collections = Object.keys(mongoose.connection.collections)
  for (let col of collections) {
    try {
      console.log('Dropping', col)
      await mongoose.connection.collections[col].drop()
    } catch (err) { /* do nothing */ }
  }
}

before('starting server', async function () {
  await start()
  await cleanUp()
})

after('stopping server', async function () {
  await cleanUp()
  await server.stop()
})
