_path = require 'path'
onmessage= require './onmessage'
logger = require './logger'
SingleSocket = require 'single-socket'

module.exports =
class Connection
  constructor: (@nsync) ->
    @pings = []

  connect: (@url, @opts, @ws = SingleSocket) ->
    @websocket = new @ws(@url, @opts)

    @websocket.on 'open', (event) =>
      @onOpen(event)

    @websocket.on 'message', (event) =>
      onmessage(event, @nsync)

    @websocket.on 'error', (err) =>
      @onClose(err)

    @websocket.on 'close', (event) =>
      @onClose(event)

  onOpen: (event) ->
    @connected = true
    @startPingsAfterInit()

    if @reconnecting
      @successfulReconnect()

    @nsync.activate()

  onClose: (event) ->
    logger.warn 'WS CLOSED:', event

    if @connected and not @reconnecting
      @nsync.disconnected()

    @connected = false
    @reconnect()

  send: (msg) ->
    if not @connected
      msg = 'The operation cannot be performed while disconnected'
      @nsync.disconnected(msg)

    logger.info 'SEND:', msg
    payload = JSON.stringify(msg)
    @websocket.send(payload)

  sendPing: (msg) ->
    logger.info 'SEND:', 'ping'
    payload = JSON.stringify(msg)
    @websocket.send(payload)

  reconnect: ->
    unless @reconnecting
      @reconnecting = true
      @nsync.connecting()

    secondsBetweenAttempts = 5
    setTimeout =>
      @connect(@ws, @url, @opts)
    , secondsBetweenAttempts * 1000

  successfulReconnect: ->
    @reconnecting = false
    @nsync.connected()

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

  waitForPong: (timestamp) ->
    secondsToWait = 4
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
      @waitForPong(timestamp)

  pong: (timestamp) ->
    i = @pings.indexOf(timestamp)

    if i > -1
      @pings.splice(i, 1)

