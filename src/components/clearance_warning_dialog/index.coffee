z = require 'zorium'

Dialog = require '../dialog'
colors = require '../../colors'
config = require '../../config'

if window?
  require './index.styl'


module.exports = class ClearanceWarningDialog
  constructor: ({@model}) ->
    @$dialog = new Dialog {
      onLeave: =>
        @model.overlay.close()
    }

  render: =>
    z '.z-clearance-warning-dialog',
      z @$dialog,
        isWide: true
        isVanilla: true
        $title: @model.l.get 'clearanceWarningDialog.title'
        $content:
          z '.z-clearance-warning-dialog_dialog',
            z '.block', @model.l.get 'clearanceWarningDialog.text1'
            z '.block', @model.l.get 'clearanceWarningDialog.text2', {
              replacements:
                name: @model.l.get 'lowClearance.maxClearance'
            }
        cancelButton:
          text: @model.l.get 'installOverlay.closeButtonText'
          onclick: =>
            @model.overlay.close()
