fs = require 'fs'
trash = require 'trash'
nsync = require './nsync-fs'

module.exports = (paths) ->
  trashPromises = []

  sorted = paths.sort (a,b) ->
    a.length - b.length

  sorted.forEach (path) ->
    node = nsync.getNode(path)
    local = node.localPath()

    fs.stat local, (err, stat) ->
      if not err?
        trashPromises.push(trash(local))

  Promise.all(trashPromises)

