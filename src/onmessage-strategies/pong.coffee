module.exports = init = (virtualFileSystem, {timestamp}) ->
  virtualFileSystem.connection.pong(timestamp)

