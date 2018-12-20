z = require 'zorium'
RxObservable = require('rxjs/Observable').Observable
RxBehaviorSubject = require('rxjs/BehaviorSubject').BehaviorSubject
require 'rxjs/add/observable/combineLatest'
_find = require 'lodash/find'

Base = require '../base'

###
not sure i like how other components extend from this...
might be better to go back to parent-child model, but need to figure out
how to get position absolute working with the extra parent div it adds
###

module.exports = class MapTooltip extends Base
  afterMount: (@$$el) =>
    super
    @disposable = @place.subscribe (place) =>
      if place
        @fadeInWhenLoaded @getThumbnailUrl place
        setTimeout =>
          @size.next {width: @$$el.offsetWidth, height: @$$el.offsetHeight}
        , 0
      else
        {isSaved} = @state.getValue()
        if isSaved
          @state.set isSaved: false
        @size.next {width: 0, height: 0}

    # update manually so we don't have to rerender
    positionAndMapSizeAndSize = RxObservable.combineLatest(
      @position, @mapSize, @size, (vals...) -> vals
    ).publishReplay(1).refCount()
    lastAnchor = null
    @disposableMap = positionAndMapSizeAndSize.subscribe (options) =>
      [position, mapSize, size] = options
      anchor = @getAnchor position, mapSize, size
      transform = @getTransform position, anchor
      @$$el.style.transform = transform
      @$$el.style.webkitTransform = transform
      if anchor isnt lastAnchor
        lastAnchor = anchor
        lastAnchorClass = _find @$$el.classList, (className) ->
          className.indexOf('anchor') isnt -1
        @$$el.classList.remove lastAnchorClass
        @$$el.classList.add "anchor-#{anchor}"

  beforeUnmount: =>
    @disposable?.unsubscribe()
    @disposableMap?.unsubscribe()

  getAnchor: (position, mapSize, size) ->
    mapWidth = mapSize?.width
    mapHeight = mapSize?.height
    xAnchor = if position?.x < size.width / 2 \
              then 'left'
              else if position?.x > mapWidth - size.width / 2
              then 'right'
              else 'center'
    yAnchor = if position?.y < size.height \
              then 'top'
              else if position?.y > mapHeight or xAnchor is 'center'
              then 'bottom'
              else 'center'
    if yAnchor in ['top', 'bottom']
      xAnchor = 'center'
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
    xPx = position?.x
    yPx = position?.y
    "translate(#{xPercent}%, #{yPercent}%) translate(#{xPx}px, #{yPx}px)"
