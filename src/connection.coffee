_path = require 'path'
onmessage= require './onmessage'
remote = require 'remote'
BrowserWindow = remote.require('browser-window')
pagebus = require('page-bus')
bus = pagebus()
AtomSocket = require('atom-socket')

module.exports =
class Connection
  constructor: (@nsync) ->
    @pings = []

  connect: (@url, @opts) ->
    @socket = new AtomSocket('fs', @url)

    @socket.on 'open', (event) =>
      @onOpen()

    @socket.on 'message', (event) =>
      onmessage(event, @nsync)

    @socket.on 'error', (err) =>
      console.error 'nsync:error', err
      @onCloseOrError()

    @socket.on 'close', (event) =>
      console.error 'nsync:closed', event
      @onCloseOrError()

    @socket.on 'open:cached', (event) =>
      @onCachedOpen()

  onCachedOpen: ->
    @onOpen()
    @nsync.init()

  onOpen: ->
    @connected = true
    @startPingsAfterInit()

    if @reconnecting
      @successfulReconnect()

    @nsync.activate()

  onCloseOrError: ->
    if @connected and not @reconnecting
      @nsync.disconnected()

    @connected = false
    @reconnect()

  send: (msg) ->
    if not @connected
      msg = 'The operation cannot be performed while disconnected'
      @nsync.disconnected(msg)

    console.log 'nsync:send', msg
    payload = JSON.stringify(msg)
    @socket.send(payload)

  sendPing: (msg) ->
    console.log 'nsync:send:ping'
    payload = JSON.stringify(msg)
    @socket.send(payload)

  reconnect: ->
    unless @reconnecting
      @reconnecting = true
      @nsync.connecting()

    secondsBetweenAttempts = 5
    setTimeout =>
      @socket.reset()
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
      @socket.reset()
    else
      @waitForPong(timestamp)

  pong: (timestamp) ->
    i = @pings.indexOf(timestamp)

    if i > -1
      @pings.splice(i, 1)

