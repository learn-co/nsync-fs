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

