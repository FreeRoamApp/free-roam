z = require 'zorium'
RxBehaviorSubject = require('rxjs/BehaviorSubject').BehaviorSubject

Icon = require '../icon'
FormattedText = require '../formatted_text'
Rating = require '../rating'
MapTooltip = require '../map_tooltip'
MapService = require '../../services/map'
colors = require '../../colors'

if window?
  require './index.styl'

module.exports = class PlaceTooltip extends MapTooltip
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
      $description: new FormattedText {
        text: @place.map (place) -> place?.description
      }
    }

    super

  getThumbnailUrl: (place) =>
    @model.image.getSrcByPrefix place?.thumbnailPrefix, {size: 'tiny'}

  render: ({isVisible} = {}) =>
    {place, $description, mapSize, size} = @state.getValue()

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
        if place?.type is 'hazard' and place?.subType is 'lowClearance'
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
          z '.description',
            $description

        if place?.type and not (place?.type in ['hazard', 'blm', 'usfs'])
          z '.rating',
            z @$rating
