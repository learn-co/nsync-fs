fs = require 'fs-plus'
logger = require '../logger'

module.exports = fetch = (nsync, {path, content}) ->
  node = nsync.getNode(path)
  if not node?
    return logger.warn 'Unable to find node with path:', path

  parent = node.parent
  stats = node.stats
  contentBuffer = new Buffer(content or '', 'base64')

  if stats.isDirectory()
    return fs.makeTree(node.localPath())

  fs.writeFile node.localPath(), contentBuffer, {}, (err) ->
    if err?
      return logger.error 'WRITE ERR', err

