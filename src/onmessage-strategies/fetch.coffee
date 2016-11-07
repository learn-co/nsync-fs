fs = require 'fs-plus'

module.exports = fetch = (virtualFileSystem, {path, content}) ->
  node = virtualFileSystem.getNode(path)
  if not node?
    return console.warn 'Unable to find node with path:', path

  parent = node.parent
  stats = node.stats
  contentBuffer = new Buffer(content or '', 'base64')

  if stats.isDirectory()
    return fs.makeTree(node.localPath())

  fs.writeFile node.localPath(), contentBuffer, {}, (err) ->
    if err?
      return console.error 'WRITE ERR', err

