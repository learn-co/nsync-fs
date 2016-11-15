logger = require './logger'
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
    logger.info 'nsync:onmessage:recieved', {type}
  catch error
    return logger.error 'nsync:onmessage:parse', {error}

  strategy = messageStrategies[type]

  if not strategy?
    logger.error 'nsync:onmessage:strategy', {error: "No strategy for #{type}"}
  else
    strategy(nsync, data)

