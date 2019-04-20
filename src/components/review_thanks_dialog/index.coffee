z = require 'zorium'

Dialog = require '../dialog'
PrimaryButton = require '../primary_button'
colors = require '../../colors'
config = require '../../config'

if window?
  require './index.styl'


module.exports = class ReviewThanksDialog
  constructor: ({@model}) ->
    @$closeButton = new PrimaryButton()
    @$dialog = new Dialog {
      onLeave: =>
        @model.overlay.close()
    }

  render: =>
    z '.z-review-thanks-dialog',
      z @$dialog,
        isWide: true
        isVanilla: false
        $content:
          z '.z-review-thanks-dialog_dialog',
            z '.title', @model.l.get 'reviewThanksDialog.title'
            z '.description', @model.l.get 'reviewThanksDialog.description'
            z '.button',
              z @$closeButton,
                text: @model.l.get 'general.close'
                isFullWidth: false
                onclick: =>
                  @model.overlay.close()
