z = require 'zorium'
RxObservable = require('rxjs/Observable').Observable
RxBehaviorSubject = require('rxjs/BehaviorSubject').BehaviorSubject
require 'rxjs/add/observable/combineLatest'
_find = require 'lodash/find'

Icon = require '../icon'
Rating = require '../rating'
Base = require '../base'
MapService = require '../../services/map'
colors = require '../../colors'

if window?
  require './index.styl'

module.exports = class PlaceTooltip extends Base
  constructor: ({@model, @router, @place, @position, @mapSize}) ->
    @$closeIcon = new Icon()
    @$directionsIcon = new Icon()
    @$addCampsiteIcon = new Icon()
    @$saveIcon = new Icon()
    @$rating = new Rating {
      value: @place.map (place) -> place?.rating
    }

    @size = new RxBehaviorSubject {width: 0, height: 0}
    myPlacesAndPlace = RxObservable.combineLatest(
      @model.savedPlace.getAll()
      @place
      (vals...) -> vals
    )

    @state = z.state {
      @place
      @mapSize
      @size
      isSaving: false
      isSaved: false
      # isSaved: myPlacesAndPlace.map ([myPlaces, place]) ->
      #   Boolean _find myPlaces, {sourceId: place?.id}
    }

  afterMount: (@$$el) =>
    super
    @disposable = @place.subscribe (place) =>
      if place
        thumbnailUrl = @getThumbnailUrl place
        @fadeInWhenLoaded thumbnailUrl
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

  getThumbnailUrl: (place) =>
    @model.image.getSrcByPrefix place?.thumbnailPrefix, 'tiny'

  saveCoordinate: =>
    {place} = @state.getValue()

    @state.set isSaving: true
    name = prompt 'Enter a name'
    @model.coordinate.upsert {
      name: name
      location: "#{place.location[1]}, #{place.location[0]}"
    }, {invalidateAll: false}
    .then ({id}) =>
      @model.savedPlace.upsert {
        sourceType: 'coordinate'
        sourceId: id
      }
    .then =>
      @state.set isSaving: false, isSaved: true

  render: ({isVisible} = {}) =>
    {place, mapSize, size, isSaving, isSaved} = @state.getValue()

    isVisible ?= Boolean place and Boolean size.width

    anchor = @getAnchor place?.position, mapSize, size
    transform = @getTransform place?.position, anchor

    isDisabled = not place or not (place.type in [
      'campground', 'overnight', 'amenity'
    ])

    z "a.z-place-tooltip.anchor-#{anchor}", {
      href: if not isDisabled and place
        @router.get place.type, {slug: place.slug}
      className: z.classKebab {isVisible, @isImageLoaded}
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
      if place?.thumbnailPrefix
        src = @getThumbnailUrl place
        z '.thumbnail',
          style:
            backgroundImage: "url(#{src})"
      z '.content',
        z '.title', place?.name
        if place?.description
          z '.description', place?.description
        if place?.type is 'coordinate'
          z '.actions',
            z '.action', {
              onclick: =>
                MapService.getDirections {
                  location:
                    lat: place.location[1]
                    lon: place.location[0]
                }, {@model}
            },
              z '.icon',
                z @$directionsIcon,
                  icon: 'directions'
                  isTouchTarget: false
                  color: colors.$bgText54
              z '.text', @model.l.get 'general.directions'
            # z '.action', {
            #   onclick: =>
            #     # TODO: pass in coordinates
            #     @router.go 'newCampground'
            # },
            #   z '.icon',
            #     z @$addCampsiteIcon,
            #       icon: 'add-circle'
            #       isTouchTarget: false
            #       color: colors.$bgText54
            #   z '.text', @model.l.get 'placeTooltip.addCampsite'
            z '.action', {
              onclick: @saveCoordinate
            },
              z '.icon',
                z @$saveIcon,
                  icon: 'star'
                  isTouchTarget: false
                  color: colors.$bgText54
              z '.text',
                if isSaving then @model.l.get 'general.saving'
                else if isSaved then @model.l.get 'general.saved'
                else @model.l.get 'general.save'

        else
          z '.rating',
            z @$rating
