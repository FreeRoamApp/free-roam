EditAmenityReview = require '../../components/new_amenity_review'
EditPlaceReviewPage = require '../edit_place_review'

module.exports = class EditAmenityReviewPage extends EditPlaceReviewPage
  EditPlaceReview: EditAmenityReview

  constructor: ({@model}) ->
    @placeModel = @model.amenity
    @placeReviewModel = @model.amenityReview
    super
