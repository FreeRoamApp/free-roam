Campground = require '../../components/campground'
PlacePage = require '../place'

module.exports = class CampgroundPage extends PlacePage
  Place: Campground

  constructor: ({@model}) ->
    @placeModel = @model.campground
    @title = @model.l.get 'campgroundPage.title'
    super
