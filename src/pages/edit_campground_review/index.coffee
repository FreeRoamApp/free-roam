EditCampgroundReview = require '../../components/new_campground_review'
EditPlaceReviewPage = require '../new_place_review'

module.exports = class EditCampgroundReviewPage extends EditPlaceReviewPage
  EditPlaceReview: EditCampgroundReview

  constructor: ({@model}) ->
    @placeModel = @model.campground
    @placeReviewModel = @model.campgroundReview
    super
