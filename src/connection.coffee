onmessage= require './onmessage'
AtomSocket = require 'atom-socket'

module.exports =
class Connection
  constructor: (@nsync) ->

  connect: (@url, @socketKey) ->
    @socket = new AtomSocket(@socketKey, @url)

    @socket.on 'open', =>
      @nsync.connected()
      @nsync.readPrimaryNodeFromCache()

    @socket.on 'message', (msg) =>
      onmessage(msg, @nsync)

    @socket.on 'error', =>
      @nsync.disconnected()

    @socket.on 'close', =>
      @nsync.disconnected()

    @socket.on 'open:cached', =>
      @nsync.init()

  send: (msg) ->
    preparedMessage = JSON.stringify(file_sync: msg)
    @socket.send(preparedMessage)

  reset: ->
    @socket.reset()

