z = require 'zorium'

Head = require '../head'
SlideSteps = require '../slide_steps'
SlideStep = require '../slide_step'
Icon = require '../icon'
config = require '../../config'
colors = require '../../colors'

if window?
  require './index.styl'

module.exports = class Onboard
  constructor: ({@model, @router}) ->
    @$slideSteps = new SlideSteps {@model, @portal}

    @$step1 = new SlideStep()
    @$step2 = new SlideStep()
    @$step3 = new SlideStep()

    @$icon1 = new Icon()
    @$icon2 = new Icon()
    @$icon3 = new Icon()

    @state = z.state
      windowSize: @model.window.getSize()

  # 1: choose from existing campgrounds, overnight stays (eg walmarts), amenities (eg dump stations)
  # 2: a little adventurous? explore new options with layers
  # 3: join us in the community (a little about us too)

  render: =>
    {windowSize} = @state.getValue()

    z '.z-onboard', {
      style:
        height: "#{windowSize?.height}px"
    },
      z @$slideSteps,
        button:
          text: @model.l.get 'signInDialog.join'
          onclick: =>
            @model.overlay.close()
        steps: [
          {
            $step: @$step1
            colorName: 'tertiary'
            $stepImage:
              z '.z-onboard_step-image.number-1'
            $stepContent:
              z '.z-onboard_step-content',
                z '.icon',
                  z @$icon1,
                    icon: 'search'
                    isTouchTarget: false
                    color: colors.$black26
                    size: if window?.matchMedia('(min-width: 768px)').matches \
                          then '40px'
                          else '24px'
                z '.title', @model.l.get 'onboard.step1Title'
                z '.description',
                  z 'div', @model.l.get 'onboard.step1Description1'
                  z 'p', @model.l.get 'onboard.step1Description2'
          }
          {
            $step: @$step2
            colorName: 'secondary'
            $stepImage:
              z '.z-onboard_step-image.number-2'
            $stepContent:
              z '.z-onboard_step-content',
                z '.icon',
                  z @$icon2,
                    icon: 'layers'
                    isTouchTarget: false
                    color: colors.$black26
                    size: if window?.matchMedia('(min-width: 768px)').matches \
                          then '40px'
                          else '24px'
                z '.title', @model.l.get 'onboard.step2Title'
                z '.description', @model.l.get 'onboard.step2Description'
          }
          {
            $step: @$step3
            colorName: 'primary'
            $stepImage:
              z '.z-onboard_step-image.number-3'
            $stepContent:
              z '.z-onboard_step-content',
                z '.icon',
                  z @$icon3,
                    icon: 'chat'
                    isTouchTarget: false
                    color: colors.$black26
                    size: if window?.matchMedia('(min-width: 768px)').matches \
                          then '40px'
                          else '24px'
                z '.title', @model.l.get 'onboard.step3Title'
                z '.description',
                  z 'div', @model.l.get 'onboard.step3Description'
                  z 'p',
                    @model.l.get 'onboard.step3Video'
                    z 'a', {
                      href: '#'
                      onclick: (e) =>
                        e?.preventDefault()
                        @model.portal.call 'browser.openWindow', {
                          url: 'https://youtu.be/yKISmxLF5V8'
                          target: '_system'
                        }
                    },
                      @model.l.get 'onboard.step3Watch'
          }
        ]
