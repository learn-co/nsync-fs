module.exports = init = (nsync, {virtualFile}) ->
  nsync.setPrimaryNode(virtualFile)
  nsync.syncPrimaryNode()

