z = require 'zorium'

Dialog = require '../dialog'
colors = require '../../colors'
config = require '../../config'

if window?
  require './index.styl'


module.exports = class WelcomeDialog
  constructor: ({@model}) ->
    @$dialog = new Dialog {
      onLeave: =>
        @model.overlay.close()
    }

  render: =>
    z '.z-welcome-dialog',
      z @$dialog,
        isWide: true
        isVanilla: true
        $title: @model.l.get 'welcomeDialog.title'
        $content:
          z '.z-welcome-dialog_dialog',
            z '.block', @model.l.get 'welcomeDialog.text1'
            z '.block', @model.l.get 'welcomeDialog.text2'
            z '.block', @model.l.get 'welcomeDialog.text3'
            z '.block',
              @model.l.get 'welcomeDialog.video'
              z 'a', {
                href: '#'
                onclick: (e) =>
                  e?.preventDefault()
                  @model.portal.call 'browser.openWindow', {
                    url: 'https://youtu.be/yKISmxLF5V8'
                    target: '_system'
                  }
              },
                @model.l.get 'welcomeDialog.watch'
            z '.block',
              z 'div', @model.l.get 'welcomeDialog.text4'
              z 'div', @model.l.get 'welcomeDialog.text5'
        cancelButton:
          text: @model.l.get 'installOverlay.closeButtonText'
          onclick: =>
            @model.overlay.close()
