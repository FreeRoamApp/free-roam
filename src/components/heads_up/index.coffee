z = require 'zorium'

Icon = require '../icon'
colors = require '../../colors'

if window?
  require './index.styl'

SLIDE_IN_TIME_MS = 250
SLIDE_OUT_TIME_MS = 250

module.exports = class HeadsUp
  constructor: ({@onHide, @notification} = {}) ->
    @$icon = new Icon()
    @state = z.state
      isVisible: false
      notification: @notification

  afterMount: =>
    @mountDisposible = @notification.subscribe (notification) =>
      if notification
        @slideIn()
        if notification.ttlMs
          setTimeout =>
            @slideOut()
          , notification.ttlMs
      else
        @slideOut()

  beforeUnmount: =>
    @mountDisposible.unsubscribe()

  slideIn: =>
    @state.set isVisible: true
    new Promise (resolve) ->
      setTimeout ->
        resolve()
      , SLIDE_IN_TIME_MS

  slideOut: =>
    @state.set isVisible: false
    new Promise (resolve) =>
      setTimeout =>
        @onHide?()
        resolve()
      , SLIDE_OUT_TIME_MS

  render: =>
    {isVisible, notification} = @state.getValue()

    notification ?= {}
    {icon, title, details, onclick} = notification

    z '.z-heads-up', {
      className: z.classKebab {isVisible}
      onclick: (e) ->
        e.preventDefault()
        onclick?()
    },
      z '.inner',
        z '.flex',
          z '.icon',
            z @$icon,
              icon: icon
              color: colors.$bgText
              isTouchTarget: 'false'
          z '.content',
            z '.title', title
            z '.details', details
