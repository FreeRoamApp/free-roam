z = require 'zorium'
RxObservable = require('rxjs/Observable').Observable
RxBehaviorSubject = require('rxjs/BehaviorSubject').BehaviorSubject
require 'rxjs/add/observable/combineLatest'
_find = require 'lodash/find'

Icon = require '../icon'
Rating = require '../rating'
colors = require '../../colors'

if window?
  require './index.styl'

module.exports = class PlaceTooltip
  constructor: ({@model, @router, @place, @position, @mapSize}) ->
    @$closeIcon = new Icon()
    @$rating = new Rating {
      value: @place.map (place) -> place?.rating
    }

    @size = new RxBehaviorSubject {width: 0, height: 0}

    @state = z.state {
      @place
      @mapSize
      @size
    }

  afterMount: (@$$el) =>
    @disposable = @place.subscribe (place) =>
      if place
        setImmediate =>
          @size.next {width: @$$el.offsetWidth, height: @$$el.offsetHeight}
      else
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

  render: ({isVisible} = {}) =>
    {place, mapSize, size} = @state.getValue()

    isVisible ?= Boolean place and Boolean size.width

    anchor = @getAnchor place?.position, mapSize, size
    transform = @getTransform place?.position, anchor

    isDisabled = place?.type isnt 'campground'

    z "a.z-place-tooltip.anchor-#{anchor}", {
      href: if not isDisabled then @router.get place?.type, {slug: place?.slug}
      className: z.classKebab {isVisible}
      onclick: (e) =>
        e?.stopPropagation()
        if place?.type is 'lowClearance'
          [lon, lat] = place.location
          @model.portal.call 'browser.openWindow', {
            url:
              "https://maps.google.com/maps?z=18&t=k&ll=#{lat},#{lon}"
          }
        else if not isDisabled
          e?.preventDefault()
          @router.goOverlay place.type, {slug: place.slug}
      style:
        transform: transform
        webkitTransform: transform
    },
      z '.close',
        z @$closeIcon,
          icon: 'close'
          size: '16px'
          isTouchTarget: false
          color: colors.$bgText54
          onclick: (e) =>
            e?.stopPropagation()
            e?.preventDefault()
            @place.next null
      if place?.thumbnailUrl
        z '.thumbnail',
          style:
            backgroundImage: "url(#{place?.thumbnailUrl})"
      z '.content',
        z '.title', place?.name
        if place?.description
          z '.description', place?.description
        z '.rating',
          z @$rating
