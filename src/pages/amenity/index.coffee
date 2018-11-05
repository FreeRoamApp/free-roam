Amenity = require '../../components/amenity'
PlacePage = require '../place'

module.exports = class AmenityPage extends PlacePage
  Place: Amenity

  constructor: ({@model}) ->
    @placeModel = @model.amenity
    super
