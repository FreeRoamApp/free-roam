z = require 'zorium'

Dialog = require '../dialog'
colors = require '../../colors'
config = require '../../config'

if window?
  require './index.styl'


module.exports = class OvernightWarningDialog
  constructor: ({@model}) ->
    @$dialog = new Dialog {
      onLeave: =>
        @model.overlay.close()
    }

  render: =>
    z '.z-overnight-warning-dialog',
      z @$dialog,
        isWide: true
        isVanilla: true
        $title: @model.l.get 'overnightWarningDialog.title'
        $content:
          z '.z-overnight-warning-dialog_dialog',
            z '.block', @model.l.get 'overnightWarningDialog.text1'
        cancelButton:
          text: @model.l.get 'installOverlay.closeButtonText'
          onclick: =>
            @model.overlay.close()
