request = require 'xhr-request'

module.exports = (url, options) ->
  new Promise (resolve, reject) ->
    xhr = request url, options, (err, data) ->
      if err
        reject err
      else
        resolve data
