fs = require 'fs-plus'
shell = require 'shell'

changeStrategies = {
  delete: (path, virtualFileSystem) ->
    node = virtualFileSystem.primaryNode.remove(path)

    return unless node?

    shell.moveItemToTrash node.localPath(), (err) ->
      if err?
        console.error 'Unable to move local file to trash:', err

    node

  moved_from: (path, virtualFileSystem) ->
    node = virtualFileSystem.primaryNode.remove(path)

    return unless node?

    # ignore weird vim write events
    return node if node.siblings().find (sibling) ->
      sibling.name is "#{node.name}.swp"

    fs.remove node.localPath(), (err) ->
      if err?
        console.error 'Unable to remove local file:', err

    node

  create: (path, virtualFileSystem, virtualFile) ->
    node = virtualFileSystem.primaryNode.add(virtualFile)

    node.findPathsToSync().then (paths) ->
      virtualFileSystem.fetch(paths)

    node

  moved_to: (path, virtualFileSystem, virtualFile) ->
    changeStrategies.create(path, virtualFileSystem, virtualFile)

  close_write: (path, virtualFileSystem, virtualFile) ->
    node = virtualFileSystem.primaryNode.update(virtualFile)
    virtualFileSystem.updated(node)

    node.determineSync().then (shouldSync) ->
      if shouldSync
        virtualFileSystem.fetch(node.path)

    node
}

module.exports = change = (virtualFileSystem, {event, path, virtualFile}) ->
  console.log "#{event.toUpperCase()}:", path
  strategy = changeStrategies[event]

  if not strategy?
    return console.warn 'No strategy for change event:', event, path

  node = strategy(path, virtualFileSystem, virtualFile)

  if not node?
    return console.warn 'Change strategy did not return node:', event, strategy

  virtualFileSystem.changed(node)

