z = require 'zorium'

Icon = require '../icon'
PrimaryButton = require '../primary_button'
colors = require '../../colors'
config = require '../../config'

if window?
  require './index.styl'

module.exports = class InstallOverlay
  constructor: ({@model}) ->
    @$overflowIcon = new Icon()
    @$closeButton = new PrimaryButton()

  render: =>
    z '.z-install-overlay',
      z '.container',
        z '.content',
          z '.title', @model.l.get 'installOverlay.title'
          z '.action',
            z '.text', @model.l.get 'installOverlay.text'
            z '.icon',
              z @$overflowIcon,
                icon: 'overflow'
                color: colors.$primary500Text
                isTouchTarget: false
          z '.instructions',
            @model.l.get 'installOverlay.instructions'
          z '.button',
            z @$closeButton, {
              text: @model.l.get 'installOverlay.closeButtonText'
              isFullWidth: false
              colors:
                cText: colors.$tertiary0Text
                c200: colors.$tertiary200
                c500: colors.$tertiary200
                c600: colors.$tertiary300
                c700: colors.$tertiary0
              onclick: =>
                @model.overlay.close()
          }
        z '.arrow'
