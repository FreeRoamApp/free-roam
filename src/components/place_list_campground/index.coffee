z = require 'zorium'
_map = require 'lodash/map'
RxObservable = require('rxjs/Observable').Observable

Icon = require '../icon'
Rating = require '../rating'
SecondaryButton = require '../secondary_button'
MapService = require '../../services/map'
colors = require '../../colors'
config = require '../../config'

if window?
  require './index.styl'

module.exports = class PlaceListCampground
  constructor: ({@model, @router, @place, @name, @action}) ->
    @$actionButton = new SecondaryButton()
    @$rating = new Rating {
      value: if @place?.map then @place else RxObservable.of @place?.rating
    }

    @defaultImages = [
      "#{config.CDN_URL}/places/empty_campground.svg"
      "#{config.CDN_URL}/places/empty_campground_green.svg"
      "#{config.CDN_URL}/places/empty_campground_blue.svg"
      "#{config.CDN_URL}/places/empty_campground_beige.svg"
    ]

    @state = z.state
      me: @model.user.getMe()
      place: @place
      name: @name
      isActionLoading: false

  getThumbnailUrl: (place) =>
    url = @model.image.getSrcByPrefix(
      place?.thumbnailPrefix, {size: 'tiny'}
    )
    if url
      url
    else
      lastChar = place?.id?.substr(place?.id?.length - 1, 1) or 'a'
      @defaultImages[\
        Math.ceil (parseInt(lastChar, 16) / 16) * (@defaultImages.length - 1)
      ]

  checkIn: (place) =>
    @model.checkIn.upsert {
      name: place.name
      sourceType: place.type
      sourceId: place.id
      status: 'visited'
      setUserLocation: true
    }

  render: ({hideRating} = {}) =>
    {me, isActionLoading, place, name} = @state.getValue()

    place ?= @place
    name ?= @name

    thumbnailSrc = @getThumbnailUrl place
    hasInfoButton = @action is 'info' and place?.type in [
      'campground', 'amenity'
    ]

    z '.z-place-list-campground',
      z '.thumbnail',
        style:
          backgroundImage: "url(#{thumbnailSrc})"
      z '.info',
        z '.name',
          name or place?.name
        if place?.distance
          z '.caption',
            @model.l.get 'placeList.distance', {
              replacements:
                distance: place?.distance.distance
                time: place?.distance.time
            }
        if place?.address?.administrativeArea
          z '.location',
            if place?.address?.locality
              "#{place?.address?.locality}, "
            place?.address?.administrativeArea
        if not hideRating
          z '.rating',
            z @$rating
      if @action
        z '.actions',
          z '.action',
            z @$actionButton,
              text: if isActionLoading \
                    then @model.l.get 'general.loading'
                    else if hasInfoButton
                    then @model.l.get 'general.info'
                    else if @action is 'info'
                    then @model.l.get 'general.directions'
                    else @model.l.get 'placeInfo.checkIn'
              isOutline: true
              heightPx: 28
              onclick: =>
                if hasInfoButton
                  @router.go place?.type, {
                    slug: place?.slug
                  }
                else if @action is 'info'
                  MapService.getDirections place, {@model}
                else
                  @state.set isActionLoading: true
                  @checkIn place
                  .then =>
                    @state.set isActionLoading: false
