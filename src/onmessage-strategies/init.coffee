wait = 100

module.exports = init = (nsync, {virtualFile}) ->
  if virtualFile.path? and virtualFile.path.length
    nsync.setPrimaryNode(virtualFile)
    nsync.syncPrimaryNode()
  else
    wait *= 2
    setTimeout ->
      nsync.init()
    , wait

