ReviewlessCampground = require '../../components/reviewless_campground'
PlacePage = require '../place'

module.exports = class ReviewlessCampgroundPage extends PlacePage
  Place: ReviewlessCampground

  constructor: ({@model}) ->
    @placeModel = @model.reviewlessCampground
    super
