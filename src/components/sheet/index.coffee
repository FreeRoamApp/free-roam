z = require 'zorium'
_defaults = require 'lodash/defaults'

Icon = require '../icon'
FlatButton = require '../flat_button'
config = require '../../config'
colors = require '../../colors'

if window?
  require './index.styl'

module.exports = class Sheet
  constructor: ({@model, @router}) ->
    @$icon = new Icon()
    @$closeButton = new FlatButton()
    @$submitButton = new FlatButton()

  render: ({icon, message, submitButton, $content}) =>
    z '.z-sheet',
      z '.overlay',
        onclick: =>
          @model.overlay.close()
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
                    color: colors.$primary500
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
                  colors: {cText: colors.$primary500}
                }
            ]
