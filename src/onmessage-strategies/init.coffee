module.exports = init = (virtualFileSystem, {virtualFile}) ->
  virtualFileSystem.setPrimaryNode(virtualFile)
  virtualFileSystem.syncPrimaryNode()
