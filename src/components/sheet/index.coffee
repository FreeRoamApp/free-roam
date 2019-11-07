z = require 'zorium'
_defaults = require 'lodash/defaults'

Icon = require '../icon'
FlatButton = require '../flat_button'
config = require '../../config'
colors = require '../../colors'

# FIXME: allow another one to be opened when this is still closing
CLOSE_DELAY_MS = 650 # 0.65s for animation

if window?
  require './index.styl'

module.exports = class Sheet
  constructor: ({@model, @router, @id}) ->
    @$icon = new Icon()
    @$closeButton = new FlatButton()
    @$submitButton = new FlatButton()

    @state = z.state {isVisible: false}

  afterMount: =>
    @state.set {isVisible: true}

  render: ({icon, message, submitButton, $content}) =>
    {isVisible} = @state.getValue()

    z '.z-sheet', {
      className: z.classKebab {isVisible}
      key: @id
    },
      z '.overlay',
        onclick: =>
          @state.set isVisible: false
          setTimeout =>
            @model.overlay.close {@id}
          , CLOSE_DELAY_MS
      z '.sheet',
        z '.inner',
          if $content
            $content
          else
            [
              z '.content',
                z '.icon',
                  z @$icon,
                    icon: icon
                    color: colors.$primaryMain
                    isTouchTarget: false
                z '.message', message
              z '.actions',
                z @$closeButton,
                  text: @model.l.get 'general.notNow'
                  isFullWidth: false
                  onclick: =>
                    @model.overlay.close()
                z @$submitButton, _defaults submitButton, {
                  isFullWidth: false
                  colors: {cText: colors.$primaryMain}
                }
            ]
