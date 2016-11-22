module.exports = ready = (nsync) ->
  nsync.init()
  nsync.connection.onReady()

