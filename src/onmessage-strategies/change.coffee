fs = require 'fs-plus'
trash = require 'trash'
logger = require '../logger'

changeStrategies = {
  delete: (path, nsync) ->
    node = nsync.primaryNode.remove(path)

    return unless node?

    trash([node.localPath()])

    node

  moved_from: (path, nsync) ->
    node = nsync.primaryNode.remove(path)

    return unless node?

    # ignore weird vim write events
    return node if node.siblings().find (sibling) ->
      sibling.name is "#{node.name}.swp"

    fs.remove node.localPath(), (err) ->
      if err?
        logger.error 'Unable to remove local file:', err

    node

  create: (path, nsync, virtualFile) ->
    node = nsync.primaryNode.add(virtualFile)

    node.findPathsToSync().then (paths) ->
      nsync.fetch(paths)

    node

  moved_to: (path, nsync, virtualFile) ->
    changeStrategies.create(path, nsync, virtualFile)

  close_write: (path, nsync, virtualFile) ->
    node = nsync.primaryNode.update(virtualFile)
    nsync.updated(node)

    node.determineSync().then (shouldSync) ->
      if shouldSync
        nsync.fetch(node.path)

    node
}

module.exports = change = (nsync, {event, path, virtualFile}) ->
  logger.log "#{event.toUpperCase()}:", path
  strategy = changeStrategies[event]

  if not strategy?
    return logger.warn 'No strategy for change event:', event, path

  node = strategy(path, nsync, virtualFile)

  if not node?
    return logger.warn 'Change strategy did not return node:', event, strategy

  nsync.changed(node)

