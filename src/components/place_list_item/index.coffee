z = require 'zorium'

PlaceListAmenity = require '../place_list_amenity'
PlaceListCampground = require '../place_list_campground'
PlaceListCoordinate = require '../place_list_coordinate'

if window?
  require './index.styl'

module.exports = class PlaceListItem
  constructor: ({@model, @router, place, action}) ->
    if place?.type
      El = if place.type is 'campground' \
           then PlaceListCampground
           else if place.type is 'amenity'
           then PlaceListAmenity
           else PlaceListCoordinate

      @$el = new El {@model, @router, place, action}
    else
      @state = z.state {
        $el: place.map (place) =>
          El = if place?.type is 'campground' \
               then PlaceListCampground
               else if place?.type is 'amenity'
               then PlaceListAmenity
               else PlaceListCoordinate

          new El {@model, @router, place, action}
      }

  render: =>
    {$el} = @state?.getValue() or {}

    z '.z-place-list-item',
      z @$el or $el
