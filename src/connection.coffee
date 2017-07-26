onmessage= require './onmessage'

module.exports =
class Connection
  constructor: (@nsync) ->

  subscribeTo: (@channel) ->
    @nsync.connected()
    @nsync.readPrimaryNodeFromCache()

    @channel.on 'file_system_event', ({file_system_event}) =>
      decoded = new Buffer(file_system_event, 'base64').toString()
      onmessage(decoded, @nsync)

    @channel.onError =>
      @nsync.disconnected()

    @channel.onClose =>
      @nsync.disconnected()

  send: (msg) ->
    @channel.push('file_system_event', data: msg)
