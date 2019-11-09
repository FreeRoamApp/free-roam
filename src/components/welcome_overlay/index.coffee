z = require 'zorium'

FlatButton = require '../flat_button'
SlideSteps = require '../slide_steps'
SecondaryButton = require '../secondary_button'
colors = require '../../colors'
config = require '../../config'

if window?
  require './index.styl'

module.exports = class WelcomeOverlay
  constructor: ({@model}) ->
    @$slideSteps = new SlideSteps {@model}
    @$skipButton = new FlatButton()
    @$watchButton = new SecondaryButton()

  render: =>
    z '.z-welcome-overlay',
      z '.skip',
        z @$skipButton, {
          text: @model.l.get 'general.skip'
          onclick: =>
            console.log 'close'
            @model.overlay.close()
        }
      z @$slideSteps,
        onDone: =>
          @model.overlay.close()
        steps: [
          {
            $content:
              z '.z-welcome-overlay_step',
                z '.image.welcome'
                z '.title', @model.l.get 'welcomeDialog.title'
                z '.content',
                  @model.l.get 'welcomeDialog.text1'
          }
          {
            $content:
              z '.z-welcome-overlay_step',
                z '.image.trips'
                z '.title', @model.l.get 'welcomeDialog.planTripsTitle'
                z '.content',
                  @model.l.get 'welcomeDialog.planTripsContent'
          }
          {
            $content:
              z '.z-welcome-overlay_step',
                z '.image.community'
                z '.title', @model.l.get 'welcomeDialog.findCommunityTitle'
                z '.content',
                   @model.l.get 'welcomeDialog.findCommunityContent'
          }
          {
            $content:
              z '.z-welcome-overlay_step',
                z '.image.video'
                z '.title', @model.l.get 'welcomeDialog.videoTitle'
                z '.content',
                   @model.l.get 'welcomeDialog.videoContent'
                 z '.action',
                   z @$watchButton,
                     text: @model.l.get 'welcomeDialog.watchTutorial'
                     onclick: =>
                       @model.portal.call 'browser.openWindow', {
                         url: 'https://youtu.be/GvRNzOFAbpg'
                         target: '_system'
                       }
          }
        ]
