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

module.exports = class PlaceListAmenity
  constructor: ({@model, @router, @place, @action}) ->
    @$infoButton = new SecondaryButton()
    @$deleteIcon = new Icon()
    placeObs = if @place?.map then @place else RxObservable.of @place?.rating
    @$rating = new Rating {
      value: placeObs
    }

    if @place?.amenities
      @amenities = _map @place?.amenities, (amenity) ->
        {
          amenity
          $icon: new Icon()
        }

    @state = z.state
      me: @model.user.getMe()
      place: @place
      amenities: placeObs.map (place) ->
        _map place?.amenities, (amenity) ->
          {
            amenity
            $icon: new Icon()
          }

  render: ({hideRating} = {}) =>
    {me, place, amenities} = @state.getValue()

    place ?= @place
    amenities ?= @amenities

    z '.z-place-list-amenity', {
      # onclick: =>
      #   if me?.username is 'austin' and confirm 'Delete?'
      #     @model.amenity.deleteByRow place
      },
        z '.info',
          z '.name',
            @place?.name
          if @place?.distance
            z '.caption',
              @model.l.get 'placeList.distance', {
                replacements:
                  distance: @place?.distance.distance
                  time: @place?.distance.time
              }
          if @place?.address?.administrativeArea
            z '.location',
              if @place?.address?.locality
                "#{@place?.address?.locality}, "
              @place?.address?.administrativeArea
          if @place?.sourceType is 'coordinate' and @place?.location
            latRounded = Math.round(@place?.location.lat * 10000) / 10000
            lonRounded = Math.round(@place?.location.lon * 10000) / 10000
            z '.coordinates', "#{latRounded}, #{lonRounded}"
          if not hideRating and @place?.sourceType isnt 'coordinate'
            z '.rating',
              z @$rating
          z '.amenities',
            _map @amenities, ({amenity, $icon}) ->
              color = colors["$icon#{amenity}"] or colors.$black
              z '.amenity', {
                style:
                  border: "1px solid #{color}"
                  color: color
              },
                z '.icon',
                  z $icon,
                    icon: amenity
                    isTouchTarget: false
                    size: '16px'
                    color: color

                z '.name', amenity

        if @action
          z '.actions',
            if @place?.sourceType isnt 'coordinate'
              z '.action',
                z @$infoButton,
                  text: if @action is 'openCheckIn'
                    @model.l.get 'general.info'
                  else
                    @model.l.get 'general.directions'
                  isOutline: true
                  heightPx: 28
                  onclick: =>
                    if @action is 'openCheckIn'
                      @router.goOverlay 'checkIn', {
                        id: place.checkInId
                      }
                    else
                      @router.goPlace place
                      # MapService.getDirections place, {@model}
