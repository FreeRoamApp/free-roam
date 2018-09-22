z = require 'zorium'
_map = require 'lodash/map'
_filter = require 'lodash/filter'

Icon = require '../icon'
colors = require '../../colors'
config = require '../../config'

if window?
  require './index.styl'

module.exports = class PlacesList
  constructor: ({@model, @router, places}) ->
    @state = z.state
      places: places.map (places) ->
        _filter _map places, (place) ->
          if place.type isnt 'cellTower'
            {
              place
              amenities: _map place.amenities, (amenity) ->
                {
                  amenity
                  $icon: new Icon()
                }
            }

  render: =>
    {places} = @state.getValue()

    z '.z-places-list',
      z '.g-grid',
        _map places, ({place, amenities}) ->
          z '.place',
            z '.name', place.name
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
