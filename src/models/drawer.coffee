RxBehaviorSubject = require('rxjs/BehaviorSubject').BehaviorSubject

module.exports = class Drawer
  constructor: ->
    @_isOpen = new RxBehaviorSubject false

  isOpen: =>
    @_isOpen

  open: =>
    # could use vanilla to open and close drawer for perf
    # (would need to get rid of all isOpens in state so it wouldn't re-render)
    @_isOpen.next true
    # prevent body scrolling while viewing menu
    document?.body.style.overflow = 'hidden'

  close: =>
    @_isOpen.next false
    document?.body.style.overflow = 'auto'
