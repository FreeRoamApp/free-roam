z = require 'zorium'
RxObservable = require('rxjs/Observable').Observable
require 'rxjs/add/observable/combineLatest'
_find = require 'lodash/find'

Icon = require '../icon'
colors = require '../../colors'

if window?
  require './index.styl'

# directionsUrl = "https://maps.apple.com/?saddr=Current%20Location&daddr=#{place.location.lat},#{place.location.lon}"

module.exports = class PlaceTooltip
  constructor: ({@model, @router, @place, @position, @mapSize}) ->
    @$closeIcon = new Icon()

    @state = z.state {
      @place
      @mapSize
    }

  afterMount: (@$$el) =>
    # update manually so we don't have to rerender
    @width = @$$el.offsetWidth
    @height = @$$el.offsetHeight
    setTimeout =>
      @width = @$$el.offsetWidth
      @height = @$$el.offsetHeight
    , 1000

    positionAndMapSize = RxObservable.combineLatest(
      @position, @mapSize, (vals...) -> vals
    ).publishReplay(1).refCount()
    lastAnchor = null
    @disposable = positionAndMapSize.subscribe ([position, mapSize]) =>
      anchor = @getAnchor position, mapSize
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

  getAnchor: (position, mapSize) =>
    mapWidth = mapSize?.width
    mapHeight = mapSize?.height
    xAnchor = if position?.x < @width / 2 \
              then 'left'
              else if position?.x > mapWidth - @width / 2
              then 'right'
              else 'center'
    yAnchor = if position?.y < @height \
              then 'top'
              else if position?.y > mapHeight or xAnchor is 'center'
              then 'bottom'
              else 'center'
    if yAnchor in ['top', 'bottom']
      xAnchor = 'center'
    "#{yAnchor}-#{xAnchor}"

  getTransform: (position, anchor) =>
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

  render: =>
    {place, mapSize} = @state.getValue()

    anchor = @getAnchor place?.position, mapSize

    transform = @getTransform place?.position, anchor

    z "a.z-place-tooltip.anchor-#{anchor}", {
      href: @router.get place?.type, {slug: place?.slug}
      className: z.classKebab {isVisible: Boolean place}
      onclick: (e) =>
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
          isTouchTarget: true
          isAlignedTop: true
          isAlignedRight: true
          color: colors.$bgText54
          onclick: (e) =>
            e?.stopPropagation()
            @place.next null
      z '.title', place?.name
      # z '.rating',
      #   z @$starRating, {rating: place?.rating}
