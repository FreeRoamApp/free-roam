z = require 'zorium'

Dialog = require '../dialog'
config = require '../../config'
colors = require '../../colors'

if window?
  require './index.styl'

module.exports = class RequestDonateDialog
  constructor: ({@model, @router}) ->
    @$dialog = new Dialog {
      onLeave: =>
        localStorage.hasSeenRequestDonate = '1'
        @model.overlay.close()
    }


  afterMount: ->
    ga? 'send', 'event', 'requestDonateDialog', 'show'

  render: =>
    z '.z-request-rating',
        z @$dialog,
          isVanilla: true
          isWide: true
          $title: @model.l.get 'requestDonateDialog.title'
          $content: @model.l.get 'requestDonateDialog.text'
          cancelButton:
            text: @model.l.get 'general.noThanks'
            isShort: true
            colors:
              cText: colors.$bgText54
            onclick: =>
              localStorage.hasSeenRequestDonate = '1'
              @model.overlay.close()
          submitButton:
            text: @model.l.get 'requestDonateDialog.donate'
            isShort: true
            colors:
              cText: colors.$secondary500
            onclick: =>
              ga? 'send', 'event', 'requestDonateDialog', 'rate'
              localStorage.hasSeenRequestDonate = '1'
              @model.overlay.close()
              @router.go 'donate'
