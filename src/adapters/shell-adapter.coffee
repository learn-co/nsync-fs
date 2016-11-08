module.exports =
class ShellAdapter
  constructor: (@nsync) ->
    # noop

  moveItemToTrash: (path) ->
    @nsync.rm(path)
    true

