module.exports = customCommand = (virtualFileSystem, {payload}) ->
  try
    data = JSON.parse(payload)
  catch
    return console.error 'Unable to parse customCommand payload:', payload

  virtualFileSystem.receivedCustomCommand(data)

