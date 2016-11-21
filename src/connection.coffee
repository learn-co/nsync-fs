onmessage= require './onmessage'
AtomSocket = require('atom-socket')

module.exports =
class Connection
  constructor: (@nsync) ->

  connect: (@url, @opts) ->
    @socket = new AtomSocket('fs', @url)

    @socket.on 'open', =>
      @onOpen()

    @socket.on 'message', (msg) =>
      onmessage(msg, @nsync)

    @socket.on 'error', =>
      @onCloseOrError()

    @socket.on 'close', =>
      @onCloseOrError()

    @socket.on 'open:cached', =>
      @onCachedOpen()

  onCachedOpen: ->
    @onOpen()
    @nsync.init()

  onOpen: ->
    @connected = true

    if @reconnecting
      @reconnecting = false
      @nsync.connected()

    @nsync.activate()

  onCloseOrError: ->
    if @connected and not @reconnecting
      @reconnecting = true
      @nsync.disconnected()

    @connected = false

  send: (msg) ->
    if not @connected
      msg = 'The operation cannot be performed while disconnected'
      @nsync.disconnected(msg)

    console.log 'nsync:send', msg
    payload = JSON.stringify(msg)
    @socket.send(payload)

