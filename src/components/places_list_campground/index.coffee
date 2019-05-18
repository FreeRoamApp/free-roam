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

module.exports = class PlacesListCampground
  constructor: ({@model, @router, @place}) ->
    @$actionButton = new SecondaryButton()
    @$rating = new Rating {
      value: RxObservable.of @place?.rating
    }

    @state = z.state
      me: @model.user.getMe()
      isActionLoading: false

  getThumbnailUrl: (place) =>
    @model.image.getSrcByPrefix(
      place?.thumbnailPrefix, {size: 'tiny'}
    ) or "#{config.CDN_URL}/empty_state/empty_campground.svg"

  checkIn: (place) =>
    console.log 'checkin', place
    @model.checkIn.upsert {
      name: place.name
      sourceType: place.type
      sourceId: place.id
      status: 'visited'
      setUserLocation: true
    }

  render: ({hideRating} = {}) =>
    {me, isActionLoading} = @state.getValue()

    thumbnailSrc = @getThumbnailUrl @place

    z '.z-places-list-campground',
      z '.thumbnail',
        style:
          backgroundImage: "url(#{thumbnailSrc})"
      z '.info',
        z '.name',
          @place?.name
        if @place?.distance
          z '.caption',
            @model.l.get 'placesList.distance', {
              replacements:
                distance: @place?.distance.distance
                time: @place?.distance.time
            }
        if @place?.address?.administrativeArea
          z '.location',
            if @place?.address?.locality
              "#{@place?.address?.locality}, "
            @place?.address?.administrativeArea
        if not hideRating
          z '.rating',
            z @$rating
      z '.actions',
        z '.action',
          z @$actionButton,
            text: if isActionLoading \
                  then @model.l.get 'general.loading'
                  else @model.l.get 'placeInfo.checkIn'
            isOutline: true
            heightPx: 28
            onclick: =>
              @state.set isActionLoading: true
              @checkIn @place
              .then =>
                @state.set isActionLoading: false
