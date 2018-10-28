Campground = require '../../components/campground'
PlacePage = require '../place'

module.exports = class CampgroundPage extends PlacePage
  Place: Campground

  constructor: ({@model}) ->
    @placeModel = @model.campground
    super
