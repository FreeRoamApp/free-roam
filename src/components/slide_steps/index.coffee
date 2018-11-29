z = require 'zorium'
_map = require 'lodash/map'
RxBehaviorSubject = require('rxjs/BehaviorSubject').BehaviorSubject

Tabs = require '../tabs'
Icon = require '../icon'
SlideStep = require '../slide_step'
SecondaryButton = require '../secondary_button'
colors = require '../../colors'
config = require '../../config'

if window?
  require './index.styl'

module.exports = class SlideSteps
  constructor: ({@model, @portal, steps}) ->
    @selectedIndex = new RxBehaviorSubject 0
    @$tabs = new Tabs {@model, hideTabBar: true, @selectedIndex}
    @$backIcon = new Icon()
    @$forwardIcon = new Icon()
    @$button = new SecondaryButton()

    @state = z.state
      selectedIndex: @selectedIndex

  render: ({onBack, onDone, steps, button, secondaryButton}) =>
    {selectedIndex} = @state.getValue()

    z '.p-slide-steps',
      z @$tabs,
        isBarFixed: false
        tabs: _map steps, ({$step, $stepContent, $stepImage, colorName}, i) ->
          {
            $menuText: "#{i}"
            $el:
              z $step, {$content: $stepContent, $image: $stepImage, colorName}
          }


      if button
        [
          z '.button-wrapper',
            z @$button, {
              onclick: button.onclick
              text: button.text
            }

            if secondaryButton
              z '.button.secondary', {
                onclick: secondaryButton.onclick
              }, secondaryButton.text
        ]

      z '.bottom-bar',
        z '.icon',
          if selectedIndex > 0
            z @$backIcon,
              icon: 'back'
              color: colors.$bgText
              onclick: =>
                @selectedIndex.next Math.max(selectedIndex - 1, 0)
          else if onBack
            z '.text', {
              onclick: onBack
            },
              'Back'
        z '.step-counter',
          _map steps, (step, i) ->
            isActive = i is selectedIndex
            z '.step-dot',
              className: z.classKebab {isActive}
        z '.icon',
          if selectedIndex < steps?.length - 1
            z @$forwardIcon,
              icon: 'arrow-right'
              color: colors.$bgText
              onclick: =>
                @selectedIndex.next \
                  Math.min(selectedIndex + 1, steps?.length - 1)
          else if onDone
            z '.text', {
              onclick: onDone
            },
              'Done'
