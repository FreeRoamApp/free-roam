z = require 'zorium'
RxBehaviorSubject = require('rxjs/BehaviorSubject').BehaviorSubject
_find = require 'lodash/find'
_uniq = require 'lodash/uniq'
_every = require 'lodash/every'

Base = require '../base'
Tooltip = require '../tooltip'
colors = require '../../colors'

if window?
  require './index.styl'

# this shows the main tooltip which is rendered in app.coffee
# if we render it here, it has issues with iscroll (having a position: fixed
# inside a transform)

module.exports = class TooltipPositioner extends Base
  TOOLTIPS:
    placeSearch:
      prereqs: null
    mapLayers:
      prereqs: ['placeSearch']
    placeTooltip:
      prereqs: null
    usersNearby:
      prereqs: null
    groupChat:
      prereqs: null

  constructor: (options) ->
    unless window? # could also return right away if cookie exists for perf
      return
    {@model, @isVisible, @offset, @key, @anchor, @$title, @$content,
      @zIndex} = options

    @isVisible ?= new RxBehaviorSubject false

    @$title ?= @model.l.get "tooltips.#{@key}Title"
    @$content ?= @model.l.get "tooltips.#{@key}Content"

    @isShown = false

    @shouldBeShown = @model.cookie.getStream().map (cookies) =>
      completed = cookies.completedTooltips?.split(',') or []
      isCompleted = completed.indexOf(@key) isnt -1
      prereqs = @TOOLTIPS[@key]?.prereqs
      not isCompleted and _every prereqs, (prereq) ->
        completed.indexOf(prereq) isnt -1
    .publishReplay(1).refCount()

  afterMount: (@$$el) =>
    super
    @disposable = @shouldBeShown.subscribe (shouldBeShown) =>
      # TODO: show main page tooltips when closing overlayPage?
      # one option is to have model.tooltip store all visible tooltips
      if shouldBeShown and not @isShown
        @isShown = true
        # despite having this, ios still calls this twice, hence the flag above
        @disposable?.unsubscribe()
        setTimeout =>
          checkIsReady = =>
            if @$$el and @$$el.clientWidth
              @_show @$$el
            else
              setTimeout checkIsReady, 100
          checkIsReady()
        , 0 # give time for re-render...

  beforeUnmount: =>
    @disposable?.unsubscribe()
    @isShown = false
    @isVisible.next false

  close: =>
    @$tooltip?.close()

  _show: ($$el) =>
    rect = $$el.getBoundingClientRect()
    initialPosition = {x: rect.left, y: rect.top}

    @$tooltip = new Tooltip {
      @model
      @key
      @anchor
      @offset
      @isVisible
      @zIndex
      initialPosition
      $title: @$title
      $content: @$content
    }
    @model.tooltip.set$ @$tooltip

  render: =>
    z '.z-tooltip-positioner', {key: "tooltip-#{@key}"}
