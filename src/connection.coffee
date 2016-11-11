_path = require 'path'
onmessage= require './onmessage'
logger = require './logger'
SingleSocket = require 'single-socket'
remote = require 'remote'
BrowserWindow = remote.require('browser-window')
pagebus = require('page-bus')
bus = pagebus()

module.exports =
class Connection
  constructor: (@nsync) ->
    console.log('nsync starting up')
    @pings = []

  connect: (@url, @opts, @ws = SingleSocket) ->
    localStorage.setItem('fs:endpoint', @url)

    @activateWebsocket()

    bus.on 'open', (event) =>
      @onOpen(event)

    bus.on 'message', (event) =>
      onmessage(event, @nsync)

    bus.on 'error', (err) =>
      @onClose(err)

    bus.on 'close', (event) =>
      @onClose(event)

  activateWebsocket: ->
    # if !localStorage.getItem('fs:websocket:started')
    localStorage.setItem('fs:websocket:started', true)
    wsWindow = new BrowserWindow({show: true, webPreferences: {devTools: true}})
    wsWindow.loadURL("file://#{ _path.join(__dirname, 'websocket.html') }")
    wsWindow.webContents.openDevTools()

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
    bus.emit('send', payload)

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

