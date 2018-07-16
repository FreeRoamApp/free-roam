RxBehaviorSubject = require('rxjs/BehaviorSubject').BehaviorSubject

module.exports = class PushNotificationSheet
  constructor: ->
    @_isOpen = new RxBehaviorSubject false
    @onCloseFn = null
    @onCompleteFn = null

  isOpen: =>
    @_isOpen

  onClose: (@onCloseFn) => null

  onComplete: (@onCompleteFn) => null

  complete: =>
    @onCompleteFn?()

  open: =>
    @_isOpen.next true
    # prevent body scrolling while viewing menu
    document.body.style.overflow = 'hidden'

  openAndWait: =>
    @open()
    new Promise (@onCompleteFn, reject) => null

  close: =>
    @_isOpen.next false
    @onClose null
    document.body.style.overflow = 'auto'
