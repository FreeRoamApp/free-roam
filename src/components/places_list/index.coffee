z = require 'zorium'
_map = require 'lodash/map'
_filter = require 'lodash/filter'

PlacesListAmenity = require '../places_list_amenity'
PlacesListCampground = require '../places_list_campground'
MapService = require '../../services/map'
colors = require '../../colors'
config = require '../../config'

if window?
  require './index.styl'

module.exports = class PlacesList
  constructor: ({@model, @router, places, action}) ->
    @state = z.state
      me: @model.user.getMe()
      places: places.map (places) =>
        _filter _map places, (place) =>
          if place.type isnt 'cellTower'
            {
              place
              $el: if place.type is 'amenity'
                new PlacesListAmenity {@model, @router, place}
              else
                new PlacesListCampground {@model, @router, place, action}
            }

  render: ({hideRating} = {}) =>
    {me, places} = @state.getValue()

    z '.z-places-list',
      z '.g-grid',
        _map places, (place) =>
          {place, $el} = place

          [
            z '.place',
              z $el, {hideRating}
            z '.divider'
          ]
