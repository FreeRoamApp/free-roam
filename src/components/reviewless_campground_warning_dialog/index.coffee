z = require 'zorium'

Dialog = require '../dialog'
colors = require '../../colors'
config = require '../../config'

if window?
  require './index.styl'


module.exports = class ReviewlessCampgroundWarningDialog
  constructor: ({@model}) ->
    @$dialog = new Dialog {
      onLeave: =>
        @model.overlay.close()
    }

  render: =>
    z '.z-reviewless-campground-warning-dialog',
      z @$dialog,
        isWide: true
        isVanilla: true
        $title: @model.l.get 'reviewlessCampgroundWarningDialog.title'
        $content:
          z '.z-reviewless-campground-warning-dialog_dialog',
            z '.block', @model.l.get 'reviewlessCampgroundWarningDialog.text1'
            z '.block', @model.l.get 'reviewlessCampgroundWarningDialog.text2'
        cancelButton:
          text: @model.l.get 'installOverlay.closeButtonText'
          onclick: =>
            @model.overlay.close()
