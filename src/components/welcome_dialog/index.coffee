z = require 'zorium'

Dialog = require '../dialog'
SlideSteps = require '../slide_steps'
SecondaryButton = require '../secondary_button'
colors = require '../../colors'
config = require '../../config'

if window?
  require './index.styl'

module.exports = class WelcomeDialog
  constructor: ({@model}) ->
    @$slideSteps = new SlideSteps {@model}
    @$watchButton = new SecondaryButton()
    @$dialog = new Dialog {
      onLeave: =>
        @model.overlay.close()
    }

  render: =>
    z '.z-welcome-dialog',
      z @$dialog,
        isWide: true
        isVanilla: false
        $content:
          z '.z-welcome-dialog_dialog',
            z @$slideSteps,
              onSkip: =>
                @model.overlay.close()
              onDone: =>
                @model.overlay.close()
              steps: [
                {
                  $content:
                    z '.z-welcome-dialog_step',
                      z '.image.welcome'
                      z '.title', @model.l.get 'welcomeDialog.title'
                      z '.content',
                        @model.l.get 'welcomeDialog.text1'
                }
                {
                  $content:
                    z '.z-welcome-dialog_step',
                      z '.image.roam'
                      z '.title', @model.l.get 'welcomeDialog.getRoamingTitle'
                      z '.content',
                        @model.l.get 'welcomeDialog.getRoamingContent'
                      z '.action',
                        z @$watchButton,
                          text: @model.l.get 'welcomeDialog.watch'
                          onclick: =>
                            @model.portal.call 'browser.openWindow', {
                              url: 'https://youtu.be/GvRNzOFAbpg'
                              target: '_system'
                            }
                }
                {
                  $content:
                    z '.z-welcome-dialog_step',
                      z '.image.help'
                      z '.title', @model.l.get 'welcomeDialog.helpTitle'
                      z '.content',
                         @model.l.get 'welcomeDialog.helpContent'
                }
              ]
        # cancelButton:
        #   text: @model.l.get 'installOverlay.closeButtonText'
        #   onclick: =>
        #     @model.overlay.close()
