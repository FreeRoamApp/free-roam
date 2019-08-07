z = require 'zorium'
_map = require 'lodash/map'
_filter = require 'lodash/filter'

PlaceListAmenity = require '../place_list_amenity'
PlaceListCampground = require '../place_list_campground'
MapService = require '../../services/map'
colors = require '../../colors'
config = require '../../config'

if window?
  require './index.styl'

module.exports = class PlaceList
  constructor: ({@model, @router, places, action}) ->
    action ?= 'checkIn'

    @state = z.state
      me: @model.user.getMe()
      places: places.map (places) =>
        _filter _map places, (place) =>
          if place.type isnt 'cellTower'
            {
              place
              $el: if place.type is 'amenity'
                new PlaceListAmenity {@model, @router, place}
              else
                new PlaceListCampground {@model, @router, place, action}
            }

  render: ({hideRating} = {}) =>
    {me, places} = @state.getValue()

    z '.z-place-list',
      z '.g-grid',
        _map places, (place) =>
          {place, $el} = place

          [
            z '.place',
              z $el, {hideRating}
            z '.divider'
          ]
