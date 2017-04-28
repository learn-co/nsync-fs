module.exports = ready = (nsync, {content}) ->
  nsync.init()
  nsync.connected()

  try
    hostIP = new Buffer(content or '', 'base64').toString()
    window.LEARN_IDE_HOST_IP = hostIP
  catch err
    console.error(err)

