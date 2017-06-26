change = require './onmessage-strategies/change'
customCommand = require './onmessage-strategies/custom-command'
error = require './onmessage-strategies/error'
fetch = require './onmessage-strategies/fetch'
init = require './onmessage-strategies/init'
open = require './onmessage-strategies/open'
ready = require './onmessage-strategies/ready'
sync = require './onmessage-strategies/sync'

messageStrategies = {
  change,
  customCommand,
  error,
  fetch,
  init,
  open,
  ready,
  sync
}

module.exports = onmessage = (message, nsync) ->
  try
    {file_sync} = JSON.parse(message)
  catch error
    return console.error 'nsync:received:parse', {error}

  if not file_sync?
    return

  {type, data} = file_sync
  console.log 'nsync:received', {type}
  strategy = messageStrategies[type]

  if not strategy?
    console.error 'nsync:strategy', "No strategy for #{type}"
  else
    strategy(nsync, data)

