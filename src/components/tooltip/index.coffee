z = require 'zorium'
RxObservable = require('rxjs/Observable').Observable
RxBehaviorSubject = require('rxjs/BehaviorSubject').BehaviorSubject
require 'rxjs/add/observable/combineLatest'
_find = require 'lodash/find'
_uniq = require 'lodash/uniq'
_every = require 'lodash/every'

Icon = require '../icon'
Rating = require '../rating'
Base = require '../base'
colors = require '../../colors'

if window?
  require './index.styl'

module.exports = class Tooltip extends Base
  TOOLTIPS:
    placeSearch:
      prereqs: null
    mapLayers:
      prereqs: ['placeSearch']
    placeTooltip:
      prereqs: null

  constructor: ({@model, @isVisible, @offset, @key, @anchor}) ->
    unless window? # could also return right away if cookie exists for perf
      return
    @$closeIcon = new Icon()

    @isVisible ?= new RxBehaviorSubject false

    @isNecessary = @model.cookie.getStream().map (cookies) =>
      completed = cookies.completedTooltips?.split(',') or []
      isCompleted = completed.indexOf(@key) isnt -1
      prereqs = @TOOLTIPS[@key]?.prereqs
      not isCompleted and _every prereqs, (prereq) ->
        completed.indexOf(prereq) isnt -1
    .publishReplay(1).refCount()

    @state = z.state {
      isNecessary: @isNecessary
      @isVisible
      anchor: null
      transform: null
    }

  afterMount: (@$$el) =>
    super
    @disposable = @isNecessary.subscribe (isNecessary) =>
      if isNecessary and not @isPositionSet
        @isPositionSet = true
        # despite having this, ios still calls this twice, hence the flag above
        @disposable?.unsubscribe()
        setTimeout =>
          checkIsReady = =>
            if @$$el and @$$el.clientWidth
              @_setPosition @$$el
            else
              setTimeout checkIsReady, 100
          checkIsReady()
        , 0 # give time for re-render...

  beforeUnmount: =>
    clearTimeout @timeout
    @disposable?.unsubscribe()

  _setPosition: ($$el) =>
    rect = $$el.getBoundingClientRect()
    windowSize = @model.window.getSize().getValue()
    position = {x: rect.left, y: rect.top}
    size = {width: rect.width, height: rect.height}
    console.log 'anchor', @anchor
    anchor = @anchor or @getAnchor position, windowSize, size
    @state.set
      anchor: anchor
      transform: @getTransform position, anchor
    @isVisible.next true

  close: =>
    completedTooltips = try
      @model.cookie.get('completedTooltips').split(',')
    catch error
      []
    completedTooltips ?= []
    @model.cookie.set 'completedTooltips', _uniq(
      completedTooltips.concat [@key]
    ).join(',')
    @isVisible.next false

  getAnchor: (position, windowSize, size) ->
    width = windowSize?.width
    height = windowSize?.height
    xAnchor = if position?.x < size.width / 2 \
              then 'left'
              else if position?.x > width - size.width# / 2
              then 'right'
              else 'center'
    yAnchor = if position?.y < size.height \
              then 'top'
              else if position?.y > height or xAnchor is 'center'
              then 'bottom'
              else 'center'
    "#{yAnchor}-#{xAnchor}"

  getTransform: (position, anchor) ->
    anchorParts = anchor.split('-')
    xPercent = if anchorParts[1] is 'left' \
               then 0
               else if anchorParts[1] is 'center'
               then -50
               else -100
    yPercent = if anchorParts[0] is 'top' \
               then 0
               else if anchorParts[0] is 'center'
               then -50
               else -100
    xPx = (position?.x or 8) + (@offset?.left or 0)
    yPx = position?.y
    "translate(#{xPercent}%, #{yPercent}%) translate(#{xPx}px, #{yPx}px)"

  render: ({$title, $content} = {}) =>
    if not window?
      return

    {isVisible, anchor, transform, isNecessary} = @state.getValue()

    isPositionSet = Boolean anchor

    # doing this causes weird things to happen (multiple mounts, ...)
    # unless isNecessary
    #   return z ''
    if not isNecessary
      return z '.z-tooltip', {key: "tooltip-#{@key}"}

    z ".z-tooltip.anchor-#{anchor}", {
      key: "tooltip-#{@key}"
      className: z.classKebab {isVisible, isPositionSet}
      style:
        transform: if isPositionSet then transform
        webkitTransform: if isPositionSet then transform
    },
      z '.close',
        z @$closeIcon,
          icon: 'close'
          size: '16px'
          isTouchTarget: false
          color: colors.$bgText54
          onclick: @close
      z '.content',
        z '.title', $title
        $content
