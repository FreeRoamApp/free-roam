z = require 'zorium'

Dialog = require '../dialog'
colors = require '../../colors'
config = require '../../config'

if window?
  require './index.styl'

module.exports = class WelcomeDialog
  constructor: ->
    @$dialog = new Dialog {
      onLeave: =>
        @model.overlay.close()
    }

  render: =>
    z '.z-get-app-dialog',
      z @$dialog,
        isVanilla: true
        $title: @model.l.get 'welcomeDialog.title'
        $content:
          z '.z-welcome-dialog_dialog', ''
          ###
          # Welcome to FreeRoam
          FreeRoam is brand new and made with ❤ from our 1987 Alpenlite 5th wheel.

          We need your help to make this app awesome.

          The single most important thing you can do to help is give us your feedback. Let us know
          what you like, what you dislike, and any features you'd like to see added. You can do so
          in chat, the forum, or by emailing us (see about page).

          The next thing you can do is help us populate a high quality list of campsites and amenities,
          by adding new ones and writing reviews for any you've been to.

          Thank you!

          ###


        cancelButton:
          text: @model.l.get 'general.cancel'
          onclick: =>
            @model.overlay.close()
