NewCampgroundReview = require '../../components/new_campground_review'
NewPlaceReviewPage = require '../new_place_review'

module.exports = class NewCampgroundReviewPage extends NewPlaceReviewPage
  NewPlaceReview: NewCampgroundReview

  constructor: ({@model}) ->
    @placeModel = @model.campground
    super
