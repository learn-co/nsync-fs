module.exports = init = (nsync, {timestamp}) ->
  nsync.connection.pong(timestamp)

