onmessage= require './onmessage'
AtomSocket = require 'atom-socket'

module.exports =
class Connection
  constructor: (@nsync) ->

  connect: (@url, @opts) ->
    @socket = new AtomSocket('fs', @url)

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
    @socket.send(msg)

  reset: ->
    @socket.reset()

