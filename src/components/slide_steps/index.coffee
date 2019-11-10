z = require 'zorium'
_map = require 'lodash/map'
RxBehaviorSubject = require('rxjs/BehaviorSubject').BehaviorSubject

Tabs = require '../tabs'
Icon = require '../icon'
colors = require '../../colors'
config = require '../../config'

if window?
  require './index.styl'

module.exports = class SlideSteps
  constructor: ({@model}) ->
    @selectedIndex = new RxBehaviorSubject 0
    @$tabs = new Tabs {@model, hideTabBar: true, @selectedIndex}
    @$backIcon = new Icon()
    @$forwardIcon = new Icon()

    @state = z.state
      selectedIndex: @selectedIndex

  render: ({onSkip, onDone, steps, doneText}) =>
    {selectedIndex} = @state.getValue()

    z '.p-slide-steps',
      z @$tabs,
        isBarFixed: false
        tabs: _map steps, ({$content}, i) ->
          {
            $menuText: "#{i}"
            $el: $content
          }

      z '.bottom-bar',
        # z '.icon',
        #   if selectedIndex > 0
        #     z @$backIcon,
        #       icon: 'back'
        #       color: colors.$bgText
        #       onclick: =>
        #         @selectedIndex.next Math.max(selectedIndex - 1, 0)
        z '.g-grid',
          if selectedIndex is 0 and onSkip
            z '.text', {
              onclick: onSkip
            },
              @model.l.get 'general.skip'
          else if selectedIndex
            z '.text', {
              onclick: =>
                @selectedIndex.next Math.max(selectedIndex - 1, 0)
            },
              @model.l.get 'general.back'
          else
            z '.text'
          z '.step-counter',
            _map steps, (step, i) ->
              isActive = i is selectedIndex
              z '.step-dot',
                className: z.classKebab {isActive}
          # z '.icon',
          #   if selectedIndex < steps?.length - 1
          #     z @$forwardIcon,
          #       icon: 'arrow-right'
          #       color: colors.$bgText
          #       onclick: =>
          #         @selectedIndex.next \
          #           Math.min(selectedIndex + 1, steps?.length - 1)
          if selectedIndex < steps?.length - 1
            z '.text', {
              onclick: =>
                @selectedIndex.next \
                  Math.min(selectedIndex + 1, steps?.length - 1)
            },
              @model.l.get 'general.next'
          else
            z '.text', {
              onclick: onDone
            },
              doneText or @model.l.get 'general.gotIt'
