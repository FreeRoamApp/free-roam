RxBehaviorSubject = require('rxjs/BehaviorSubject').BehaviorSubject

module.exports = class SignInDialog
  constructor: ->
    @_isOpen = new RxBehaviorSubject false
    @_mode = new RxBehaviorSubject 'join'
    @onLoggedInFn = null
    @onCancelFn = null

  isOpen: =>
    @_isOpen

  onLoggedIn: (@onLoggedInFn) => null

  onCancel: (@onCancelFn) => null

  loggedIn: =>
    @onLoggedInFn?()

  cancel: =>
    @onCancelFn?()

  openIfGuest: (user) =>
    new Promise (resolve, reject) =>
      if user?.isMember
        resolve true
      else
        @open()
        @onLoggedIn resolve
        @onCancel reject

  getMode: =>
    @_mode

  setMode: (mode) =>
    @_mode.next mode

  open: (mode) =>
    mode ?= 'join'
    @setMode mode
    @_isOpen.next true
    # prevent body scrolling while viewing menu
    document.body.style.overflow = 'hidden'

  close: =>
    @_isOpen.next false
    @onLoggedIn null
    document.body.style.overflow = 'auto'
