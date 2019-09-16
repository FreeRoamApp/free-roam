z = require 'zorium'

Dialog = require '../dialog'
colors = require '../../colors'
config = require '../../config'

if window?
  require './index.styl'


module.exports = class GoogleMapsWarningDialog
  constructor: ({@model}) ->
    @$dialog = new Dialog {
      onLeave: =>
        @model.overlay.close()
    }

  render: =>
    z '.z-google-maps-warning-dialog',
      z @$dialog,
        isWide: true
        isVanilla: true
        $title: @model.l.get 'googleMapsWarningDialog.title'
        $content:
          z '.z-google-maps-warning-dialog_dialog',
            z '.block', @model.l.get 'googleMapsWarningDialog.text1'
            z '.block', @model.l.get 'googleMapsWarningDialog.text2'
        cancelButton:
          text: @model.l.get 'installOverlay.closeButtonText'
          onclick: =>
            @model.overlay.close()
