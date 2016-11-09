logger = require '../logger'

module.exports = error = (nsync, {event, error}) ->
  logger.log 'Error:', event, error

