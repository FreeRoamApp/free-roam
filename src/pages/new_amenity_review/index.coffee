NewAmenityReview = require '../../components/new_amenity_review'
NewPlaceReviewPage = require '../new_place_review'

module.exports = class NewAmenityReviewPage extends NewPlaceReviewPage
  NewPlaceReview: NewAmenityReview

  constructor: ({@model}) ->
    @placeModel = @model.amenity
    super
