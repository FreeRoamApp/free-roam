config = require '../config'

module.exports = class Time
  constructor: ({@auth}) ->
    @serverTime = Date.now()
    @timeInterval = setInterval =>
      @serverTime += 1000
    , 1000

    setTimeout =>
      @updateServerTime()
    , 100

  updateServerTime: =>
    @auth.stream 'time.get'
    .take(1).subscribe (timeObj) =>
      @serverTime = Date.parse timeObj.now

  getServerTime: =>
    @serverTime

  dispose: =>
    clearInterval @timeInterval
