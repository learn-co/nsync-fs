change = require './onmessage-strategies/change'
customCommand = require './onmessage-strategies/custom-command'
error = require './onmessage-strategies/error'
fetch = require './onmessage-strategies/fetch'
init = require './onmessage-strategies/init'
open = require './onmessage-strategies/open'
pong = require './onmessage-strategies/pong'
ready = require './onmessage-strategies/ready'
sync = require './onmessage-strategies/sync'

messageStrategies = {
  change,
  customCommand,
  error,
  fetch,
  init,
  open,
  pong,
  ready,
  sync
}

module.exports = onmessage = (message, nsync) ->

  try
    {type, data} = JSON.parse(message)
    console.log 'nsync:received', {type}
  catch error
    return console.error 'nsync:received:parse', {error}

  strategy = messageStrategies[type]

  if not strategy?
    console.error 'nsync:strategy', "No strategy for #{type}"
  else
    strategy(nsync, data)

