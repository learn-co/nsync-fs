_path = require 'path'
onmessage= require './onmessage'

module.exports =
class ConnectionManager
  constructor: (@virtualFileSystem) ->
    @pings = []

  connect: (@ws, @url, @opts) ->
    @websocket = new @ws(@url, @opts)

    @websocket.on 'open', (event) =>
      @onOpen(event)

    @websocket.on 'message', (event) =>
      onmessage(event, @virtualFileSystem)

    @websocket.on 'error', (err) =>
      @onClose(err)

    @websocket.on 'close', (event) =>
      @onClose(event)

  onOpen: (event) ->
    @connected = true
    @startPingsAfterInit()

    if @reconnecting
      @successfulReconnect()

    @virtualFileSystem.activate()
    @virtualFileSystem.init()

  onClose: (event) ->
    console.warn 'WS CLOSED:', event

    if @connected and not @reconnecting
      @virtualFileSystem.disconnected()

    @connected = false
    @reconnect()

  send: (msg) ->
    if not @connected
      msg = 'The operation cannot be performed while disconnected'
      @virtualFileSystem.disconnected(msg)

    console.log 'SEND:', msg
    payload = JSON.stringify(msg)
    @websocket.send(payload)

  sendPing: (msg) ->
    console.log 'SEND:', 'ping'
    payload = JSON.stringify(msg)
    @websocket.send(payload)

  reconnect: ->
    unless @reconnecting
      @reconnecting = true
      @virtualFileSystem.connecting()

    secondsBetweenAttempts = 5
    setTimeout =>
      @connect(@ws, @url, @opts)
    , secondsBetweenAttempts * 1000

  successfulReconnect: ->
    @reconnecting = false
    @virtualFileSystem.connected()

  startPingsAfterInit: ->
    # TODO: something cleaner, this simply waits n minutes after init is sent
    minutes = 3
    setTimeout =>
      @ping()
    , minutes * 60 * 1000

  ping: ->
    return if not @connected

    timestamp = (new Date).toString()
    @pings.push(timestamp)

    @sendPing {command: 'ping', timestamp}
    @waitForPong(timestamp)

  waitForPong: (timestamp, secondsToWait = 3) ->
    isRepeat = timestamp is @currentPing
    @currentPing = timestamp

    setTimeout =>
      @resolvePing(timestamp, isRepeat)
    , secondsToWait * 1000

  resolvePing: (timestamp, isRepeat) ->
    if not @pings.includes(timestamp)
      return @ping()

    if isRepeat
      @websocket.close()
    else
      @waitForPong(timestamp, 5)

  pong: (timestamp) ->
    i = @pings.indexOf(timestamp)

    if i > -1
      @pings.splice(i, 1)

