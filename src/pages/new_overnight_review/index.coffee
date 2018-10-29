NewOvernightReview = require '../../components/new_overnight_review'
NewPlaceReviewPage = require '../new_place_review'

module.exports = class NewOvernightReviewPage extends NewPlaceReviewPage
  NewPlaceReview: NewOvernightReview

  constructor: ({@model}) ->
    @placeModel = @model.overnight
    super
