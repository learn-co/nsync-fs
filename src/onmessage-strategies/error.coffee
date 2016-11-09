logger = require '../logger'

module.exports = error = (nsync, {event, error}) ->
  logger.info 'Error:', event, error

