fs = require 'fs-plus'

module.exports =
class FSAdapter
  constructor: (@nsync) ->
    # noop

  existsSync: (path) ->
    @nsync.hasPath(path)

  isBinaryExtension: (ext) ->
    fs.isBinaryExtension(ext)

  isCaseInsensitive: ->
    fs.isCaseInsensitive()

  isCompressedExtension: (ext) ->
    fs.isCompressedExtension(ext)

  isDirectorySync: (path) ->
    @nsync.isDirectory(path)

  isFileSync: (path) ->
    @nsync.isFile(path)

  isImageExtension: (ext) ->
    fs.isImageExtension(ext)

  isPdfExtension: (ext) ->
    fs.isPdfExtension(ext)

  isReadmePath: (path) ->
    fs.isReadmePath(path)

  isSymbolicLinkSync: (path) ->
    @nsync.isSymbolicLink(path)

  lstatSyncNoException: (path) ->
    @nsync.lstat(path)

  listSync: (path, extensions) ->
    @nsync.list(path, extensions)

  readFileSync: (path) ->
    @nsync.read(path)

  readdirSync: (path) ->
    @nsync.readdir(path)

  realpathSync: (path) ->
    @nsync.realpath(path)

  realpath: (path) ->
    @nsync.realpath(path)

  statSync: (path) ->
    @nsync.stat(path) or
      throw new Error("No virtual entry (file or directory) could be found by the given path '#{path}'")

  statSyncNoException: (path) ->
    @nsync.stat(path)

  absolute: -> # currently used only in spec
    atom.notifications.addWarning('Unadapted fs function', detail: 'absolute')

  copy: (source, destination) ->
    @nsync.cp(source, destination)

  copySync: (source, destination) ->
    @nsync.cp(source, destination)

  makeTreeSync: (path) ->
    @nsync.mkdirp(path)

  moveSync: (source, destination) ->
    @nsync.mv(source, destination)

  writeFileSync: (path) ->
    @nsync.touch(path)

  mkdirSync: -> # currently used only in spec
    atom.notifications.addWarning('Unadapted fs function', detail: 'mkdirSync')

  removeSync: -> # currently used only in spec
    atom.notifications.addWarning('Unadapted fs function', detail: 'removeSync')

  symlinkSync: -> # currently used only in spec
    atom.notifications.addWarning('Unadapted fs function', detail: 'symlinkSync')

