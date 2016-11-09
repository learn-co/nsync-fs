logger = require '../logger'

module.exports = customCommand = (nsync, {payload}) ->
  try
    data = JSON.parse(payload)
  catch
    return logger.error 'Unable to parse customCommand payload:', payload

  nsync.receivedCustomCommand(data)

