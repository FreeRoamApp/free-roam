RxBehaviorSubject = require('rxjs/BehaviorSubject').BehaviorSubject
_filter = require 'lodash/filter'

module.exports = class Overlay
  constructor: ->
    @overlay$ = new RxBehaviorSubject null
    @_data = new RxBehaviorSubject null
    @onCompleteFn = null
    @onCancelFn = null

  onComplete: (@onCompleteFn) => null

  onCancel: (@onCancelFn) => null

  complete: =>
    @onCompleteFn?()

  cancel: =>
    @onCancelFn?()

  openAndWait: =>
    @open.apply this, arguments
    new Promise (@onCompleteFn, reject) => null

  getData: =>
    @_data

  setData: (data) =>
    @_data.next data

  get$: =>
    @overlay$

  open: ($, data) =>
    console.log 'open'
    @overlay$.next _filter (@overlay$.getValue() or []).concat $
    @setData data
    # prevent body scrolling while viewing menu
    document.body.style.overflow = 'hidden'

  close: =>
    @overlay$.next null
    @onComplete null
    document.body.style.overflow = 'auto'
