Cache = require './cache'
Portal = require './portal'
Push = require './push'
config = require '../config'

push = new Push()
push.listen()

cache = new Cache()
cache.listen()

portal = new Portal {cache}
portal.listen()

self.onerror = (message, file, line, column, error) ->
  # if we log with `new Error` it's pretty pointless (gives error message that
  # just points to this line). if we pass the 5th argument (error), it breaks
  # on json.stringify
  err = {message, file, line, column}
  fetch config.API_URL + '/log',
    method: 'POST'
    headers:
      'Content-Type': 'text/plain' # Avoid CORS preflight
    body: JSON.stringify
      event: 'client_error'
      trace: null # trace
      error: 'INSIDE SW ERR' + JSON.stringify(err)
  .catch (err) ->
    console?.log 'logs post', err
