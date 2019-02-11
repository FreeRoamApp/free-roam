z = require 'zorium'
_map = require 'lodash/map'
_filter = require 'lodash/filter'
RxObservable = require('rxjs/Observable').Observable

Icon = require '../icon'
Rating = require '../rating'
FlatButton = require '../flat_button'
MapService = require '../../services/map'
colors = require '../../colors'
config = require '../../config'

if window?
  require './index.styl'

module.exports = class PlacesList
  constructor: ({@model, @router, places}) ->
    @state = z.state
      me: @model.user.getMe()
      places: places.map (places) ->
        _filter _map places, (place) ->
          if place.type isnt 'cellTower'
            {
              place
              $rating: new Rating {
                value: RxObservable.of place.rating
              }
              amenities: _map place.amenities, (amenity) ->
                {
                  amenity
                  $icon: new Icon()
                }
              $detailsButton: new FlatButton()
              $directionsButton: new FlatButton()
              $deleteIcon: new Icon()
            }

  render: ({hideRating} = {}) =>
    {me, places} = @state.getValue()

    z '.z-places-list',
      z '.g-grid',
        _map places, (place) =>
          {place, $rating, amenities, $detailsButton,
            $directionsButton, $deleteIcon} = place

          z '.place', {
            onclick: =>
              if me?.username is 'austin' and confirm 'Delete?'
                @model.amenity.deleteByRow place
          },
            z '.info',
              z '.name',
                place.name
              if place.address?.administrativeArea
                z '.location',
                  if place.address?.locality
                    "#{place.address?.locality}, "
                  place.address?.administrativeArea
              if place.sourceType is 'coordinate' and place.location
                latRounded = Math.round(place.location.lat * 10000) / 10000
                lonRounded = Math.round(place.location.lon * 10000) / 10000
                z '.coordinates', "#{latRounded}, #{lonRounded}"
              if not hideRating and place.sourceType isnt 'coordinate'
                z '.rating',
                  z $rating
              z '.amenities',
                _map amenities, ({amenity, $icon}) ->
                  z '.amenity',
                    z '.icon',
                      z $icon,
                        icon: amenity
                        isTouchTarget: false
                        size: '16px'
                        color: colors["$amenity#{amenity}"]

                    z '.name', amenity

            z '.actions',
              if place?.sourceType isnt 'coordinate'
                z '.action',
                  z $detailsButton,
                    text: @model.l.get 'general.info'
                    onclick: =>
                      @router.goPlace place
              z '.action',
                z $directionsButton,
                  text: @model.l.get 'general.directions'
                  onclick: =>
                    MapService.getDirections place, {@model}
              # z '.action',
              #   z $deleteIcon,
              #     icon: 'delete'
              #     isTouchTarget: false
              #     onclick: =>
