
module.exports = customCommand = (nsync, {payload}) ->
  try
    data = JSON.parse(payload)
  catch
    return console.error 'Unable to parse customCommand payload:', payload

  nsync.receivedCustomCommand(data)

