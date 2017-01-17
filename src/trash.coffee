fs = require 'fs'
trash = require 'trash'

module.exports = (paths, nsync) ->
  trashPromises = []

  sorted = paths.sort (a,b) ->
    a.length - b.length

  sorted.forEach (path) ->
    node = nsync.getNode(path)
    return unless node?

    local = node.localPath()
    fs.stat local, (err, stat) ->
      if not err?
        trashPromises.push(trash(local))

  Promise.all(trashPromises)

