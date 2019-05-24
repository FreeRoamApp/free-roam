z = require 'zorium'
_map = require 'lodash/map'
RxObservable = require('rxjs/Observable').Observable

Icon = require '../icon'
Rating = require '../rating'
FlatButton = require '../flat_button'
MapService = require '../../services/map'
colors = require '../../colors'
config = require '../../config'

if window?
  require './index.styl'

module.exports = class PlacesListAmenity
  constructor: ({@model, @router, @place}) ->
    @$detailsButton = new FlatButton()
    @$directionsButton = new FlatButton()
    @$deleteIcon = new Icon()
    @$rating = new Rating {
      value: RxObservable.of @place?.rating
    }
    @amenities = _map @place?.amenities, (amenity) ->
      {
        amenity
        $icon: new Icon()
      }

    @state = z.state
      me: @model.user.getMe()

  render: ({hideRating} = {}) =>
    {me} = @state.getValue()

    z '.z-places-list-amenity', {
      # onclick: =>
      #   if me?.username is 'austin' and confirm 'Delete?'
      #     @model.amenity.deleteByRow place
      },
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
          if @place?.sourceType is 'coordinate' and @place?.location
            latRounded = Math.round(@place?.location.lat * 10000) / 10000
            lonRounded = Math.round(@place?.location.lon * 10000) / 10000
            z '.coordinates', "#{latRounded}, #{lonRounded}"
          if not hideRating and @place?.sourceType isnt 'coordinate'
            z '.rating',
              z @$rating
          z '.amenities',
            _map @amenities, ({amenity, $icon}) ->
              color = colors["$amenity#{amenity}"] or colors.$black
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

        z '.actions',
          if @place?.sourceType isnt 'coordinate'
            z '.action',
              z @$detailsButton,
                icon: 'info'
                text: @model.l.get 'general.info'
                colors:
                  cText: colors.$primary500
                onclick: =>
                  @router.goPlace @place
          z '.action',
            z @$directionsButton,
              text: @model.l.get 'general.directions'
              icon: 'directions'
              colors:
                cText: colors.$primary500
              onclick: =>
                MapService.getDirections @place, {@model}
          # z '.action',
          #   z $deleteIcon,
          #     icon: 'delete'
          #     isTouchTarget: false
          #     onclick: =>
