RxObservable = require('rxjs/Observable').Observable
require 'rxjs/add/observable/fromPromise'

request = require '../services/request'
config = require '../config'

PATH = 'https://api.giphy.com/v1/gifs'

module.exports = class Gif
  search: (query, {limit}) ->
    RxObservable.fromPromise request "#{PATH}/search",
      json: true
      query:
        q: query
        limit: limit
        api_key: config.GIPHY_API_KEY
