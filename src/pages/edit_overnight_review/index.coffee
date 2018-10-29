EditOvernightReview = require '../../components/new_overnight_review'
EditPlaceReviewPage = require '../edit_place_review'

module.exports = class EditOvernightReviewPage extends EditPlaceReviewPage
  EditPlaceReview: EditOvernightReview

  constructor: ({@model}) ->
    @placeModel = @model.overnight
    @placeReviewModel = @model.overnightReview
    super
