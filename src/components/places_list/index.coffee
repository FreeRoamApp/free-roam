z = require 'zorium'
_map = require 'lodash/map'
_filter = require 'lodash/filter'
RxObservable = require('rxjs/Observable').Observable

Icon = require '../icon'
Rating = require '../rating'
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
            }

  render: ({hideRating} = {}) =>
    {me, places} = @state.getValue()

    z '.z-places-list',
      z '.g-grid',
        _map places, ({place, $rating, amenities}) =>
          z '.place', {
            onclick: =>
              @router.goPlace place
              if me?.username is 'austin' and confirm 'Delete?'
                @model.amenity.deleteByRow place
          },
            z '.name', place.name
            unless hideRating
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
