_ = require 'underscore-plus'
_path = require 'path'
convert = require './util/path-converter'
fs = require 'fs-plus'
shell = require 'shell'
{Emitter} = require 'event-kit'
AtomHelper = require './atom-helper'
ConnectionManager = require './connection-manager'
FSAdapter = require './adapters/fs-adapter'
FileSystemNode = require './file-system-node'
ShellAdapter = require './adapters/shell-adapter'

module.exports =
class VirtualFileSystem
  constructor: ->
    @emitter = new Emitter
    @atomHelper = new AtomHelper(this)
    @fs = new FSAdapter(this)
    @shell = new ShellAdapter(this)
    @primaryNode = new FileSystemNode({})
    @connectionManager = new ConnectionManager(this)

  configure: ({@expansionState, @localRoot}) ->
    @setLocalPaths()
    @connectionManager.connect()
    @emitter.emit('did-configure')

  setLocalPaths: ->
    convert.configure({@localRoot})

    @logDirectory = _path.join(@localRoot, 'var', 'log')
    @receivedLog = _path.join(@logDirectory, 'received')
    @sentLog = _path.join(@logDirectory, 'sent')

    @cacheDirectory = _path.join(@localRoot, 'var', 'cache')
    @cachedPrimaryNode = _path.join(@cacheDirectory, 'primary-node')

    fs.makeTreeSync(@logDirectory)
    fs.makeTreeSync(@cacheDirectory)

  serialize: ->
    @primaryNode.serialize()

  cache: ->
    serializedNode = @serialize()

    if serializedNode.path?
      data = JSON.stringify(serializedNode)
      fs.writeFile(@cachedPrimaryNode, data)

  loading: ->
    secondsTillNotifying = 3

    setTimeout =>
      if not @primaryNode.path?
        @loadingNotification = @atomHelper.loading()
    , secondsTillNotifying * 1000

  setPrimaryNodeFromCache: (serializedNode) ->
    return if @primaryNode.path?

    @primaryNode = new FileSystemNode(serializedNode)
    @atomHelper.updateProject(@primaryNode.localPath(), @expansionState)

  setPrimaryNode: (serializedNode) ->
    @primaryNode = new FileSystemNode(serializedNode)

    @loadingNotification?.dismiss()
    @loadingNotification = null

    @atomHelper.updateProject(@primaryNode.localPath(), @expansionState)
    @sync(@primaryNode.path)

  activate: ->
    fs.readFile @cachedPrimaryNode, (err, data) =>
      if err?
        console.error 'Unable to load cached project node:', err
        @loading()
        return

      try
        serializedNode = JSON.parse(data)
      catch error
        console.error 'Unable to parse cached project node:', error
        @loading()
        return

      @setPrimaryNodeFromCache(serializedNode)

  send: (msg) ->
    convertedMsg = {}

    for own key, value of msg
      if typeof value is 'string' and value.startsWith(@localRoot)
        convertedMsg[key] = convert.localToRemote(value)
      else
        convertedMsg[key] = value

    @connectionManager.send(convertedMsg)

  # ------------------
  # File introspection
  # ------------------

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

