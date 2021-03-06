_path = require 'path'
convert = require './convert'
fs = require 'fs-plus'
{Emitter} = require 'event-kit'
Connection = require './connection'
FSAdapter = require './adapters/fs-adapter'
FilesystemNode = require './filesystem-node'
ShellAdapter = require './adapters/shell-adapter'

class Nsync
  constructor: ->
    @emitter = new Emitter
    @fs = new FSAdapter(this)
    @shell = new ShellAdapter(this)
    @primaryNode = new FilesystemNode({})
    @connection = new Connection(this)

  configure: ({@expansionState, @localRoot, channel}) ->
    @setLocalPaths()

    @connection.subscribeTo(channel)

    @emitter.emit('did-configure')

  setLocalPaths: ->
    convert.configure({@localRoot})

    @logDirectory = _path.join(@localRoot, 'var', 'log')
    @receivedLog = _path.join(@logDirectory, 'received')
    @sentLog = _path.join(@logDirectory, 'sent')

    fs.makeTreeSync(@logDirectory)

  disconnected: ->
    @isConnected = false
    @emitter.emit('did-disconnect')

  disconnectedSend: (msg) ->
    @emitter.emit('did-send-while-disconnected', msg)

  connected: ->
    @isConnected = true
    @emitter.emit('did-connect')

  loading: ->
    @emitter.emit('will-load')

  opened: (file) ->
    @emitter.emit('did-open', file)

  receivedCustomCommand: (payload) ->
    @emitter.emit('did-receive-custom-command', payload)

  changed: (node) ->
    @emitter.emit('did-change', node.localPath())

  updated: (node) ->
    @emitter.emit('did-update', node.localPath())

  setPrimaryNode: (serializedNode) ->
    @primaryNode = new FilesystemNode(serializedNode)

    localPath = @primaryNode.localPath()
    @emitter.emit('did-set-primary', {localPath, @expansionState})

  syncPrimaryNode: ->
    @sync(@primaryNode.path)

  send: (msg) ->
    convertedMsg = {}

    for own key, value of msg
      if typeof value is 'string' and value.startsWith(@localRoot)
        convertedMsg[key] = convert.localToRemote(value)
      else
        convertedMsg[key] = value

    if @isConnected is false
      @disconnectedSend(convertedMsg)

    @connection.send(convertedMsg)

  # ------------------
  # File introspection
  # ------------------

  hasPrimaryNode: ->
    @primaryNode.path?

  getNode: (path) ->
    @primaryNode.get(path)

  hasPath: (path) ->
    @primaryNode.has(path)

  isDirectory: (path) ->
    @stat(path).isDirectory()

  isFile: (path) ->
    @stat(path).isFile()

  isSymbolicLink: (path) ->
    @stat(path).isSymbolicLink()

  list: (path, extension) ->
    @getNode(path).list(extension)

  lstat: (path) ->
    # TODO: lstat
    @stat(path)

  read: (path) ->
    @getNode(path)

  readdir: (path) ->
    @getNode(path).entries()

  realpath: (path) ->
    # TODO: realpath
    path

  stat: (path) ->
    @getNode(path)?.stats

  # ---------------
  # File operations
  # ---------------

  init: ->
    @send {command: 'init'}

  cp: (source, destination) ->
    @send {command: 'cp', source, destination}

  mv: (source, destination) ->
    @send {command: 'mv', source, destination}

  mkdirp: (path) ->
    @send {command: 'mkdirp', path}

  touch: (path) ->
    @send {command: 'touch', path}

  rm: (path) ->
    @send {command: 'rm', path}

  sync: (path) ->
    @send {command: 'sync', path}

  open: (path) ->
    @send {command: 'open', path}

  fetch: (paths) ->
    paths = [paths] if typeof paths is 'string'

    if paths.length
      @send {command: 'fetch', paths}

  save: (path, content) ->
    @send {command: 'save', path, content}

  # ------------------
  # Event subscription
  # ------------------

  onDidConfigure: (callback) ->
    @emitter.on 'did-configure', callback

  onDidSetPrimary: (callback) ->
    @emitter.on 'did-set-primary', callback

  onWillLoad: (callback) ->
    @emitter.on 'will-load', callback

  onDidDisconnect: (callback) ->
    @emitter.on 'did-disconnect', callback

  onDidSendWhileDisconnected: (callback) ->
    @emitter.on 'did-send-while-disconnected', callback

  onDidConnect: (callback) ->
    @emitter.on 'did-connect', callback

  onDidReceiveCustomCommand: (callback) ->
    @emitter.on 'did-receive-custom-command', callback

  onDidChange: (callback) ->
    @emitter.on 'did-change', callback

  onDidUpdate: (callback) ->
    @emitter.on 'did-update', callback

  onDidOpen: (callback) ->
    @emitter.on 'did-open', callback

module.exports = new Nsync

