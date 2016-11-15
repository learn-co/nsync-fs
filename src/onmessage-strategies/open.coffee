fs = require 'fs-plus'

module.exports = open = (nsync, {path, content}) ->
  node = nsync.getNode(path)
  if not node?
    return console.warn 'Unable to find node with path:', path

  parent = node.parent
  stats = node.stats
  contentBuffer = new Buffer(content or '', 'base64')

  if stats.isDirectory()
    return fs.makeTree(node.localPath())

  fs.writeFile node.localPath(), contentBuffer, {mode: stats.mode}, (err) ->
    if err?
      return console.error 'WRITE ERR', err
    nsync.opened({path: node.path, localPath: node.localPath()})

