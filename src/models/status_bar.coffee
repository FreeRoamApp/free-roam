RxBehaviorSubject = require('rxjs/BehaviorSubject').BehaviorSubject

module.exports = class StatusBar
  constructor: ->
    @_data = new RxBehaviorSubject null

  getData: =>
    @_data

  open: (data) =>
    @_data.next data
    if data?.timeMs
      setTimeout @close, data.timeMs

  close: =>
    @_data.next null
