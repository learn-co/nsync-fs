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

  reconnect: ->
    if not @reconnecting
      @reconnecting = true
      @nsync.connecting()

    secondsBetweenAttempts = 5
    setTimeout =>
      @conditionallyReset()
    , secondsBetweenAttempts * 1000

  successfulReconnect: ->
    @reconnecting = false
    @nsync.connected()

  conditionallyReset: ->
    if not @connected
      @reset()

  reset: ->
    @socket.reset()

