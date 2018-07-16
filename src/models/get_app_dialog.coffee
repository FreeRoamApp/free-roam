RxBehaviorSubject = require('rxjs/BehaviorSubject').BehaviorSubject

module.exports = class GetAppDialog
  constructor: ->
    @_isOpen = new RxBehaviorSubject false

  isOpen: =>
    @_isOpen

  open: =>
    @_isOpen.next true
    # prevent body scrolling while viewing menu
    document.body.style.overflow = 'hidden'

  close: =>
    @_isOpen.next false
    document.body.style.overflow = 'auto'
