_path = require 'path'
onmessage= require './onmessage'

module.exports =
class ConnectionManager
  constructor: (@virtualFileSystem) ->

  connect: (websocket, url, {spawn}) ->
    @websocket = new websocket(url, {spawn})

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

    if @reconnectNotification?
      @successfulReconnect()

    @virtualFileSystem.activate()
    @virtualFileSystem.init()

  onClose: (event) ->
    console.warn 'WS CLOSED:', event

    if @connected and not @reconnectNotification?
      @connected = false
      @virtualFileSystem.atomHelper.disconnected()

    @reconnect()

  send: (msg) ->
    if not @connected
      @virtualFileSystem.atomHelper.error 'Learn IDE: you are not connected!',
        detail: 'The operation cannot be performed while disconnected'

    console.log 'SEND:', msg
    payload = JSON.stringify(msg)
    @websocket.send(payload)

  sendPing: (msg) ->
    console.log 'SEND:', 'ping'
    payload = JSON.stringify(msg)
    @websocket.send(payload)

  reconnect: ->
    if not @reconnectNotification?
      @reconnectNotification = @virtualFileSystem.atomHelper.connecting()

    secondsBetweenAttempts = 5
    setTimeout =>
      @connect()
    , secondsBetweenAttempts * 1000

  successfulReconnect: ->
    @reconnectNotification.dismiss()
    @reconnectNotification = null
    @virtualFileSystem.atomHelper.success 'Learn IDE: connected!'

  startPingsAfterInit: ->
    # TODO: something cleaner, this simply waits n minutes after init is sent
    minutes = 3
    setTimeout =>
      @ping()
    , minutes * 60 * 1000

  ping: ->
    return if not @connected

    @pings ?= []
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
    @pings.splice(i, 1)

