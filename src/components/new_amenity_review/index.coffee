RxBehaviorSubject = require('rxjs/BehaviorSubject').BehaviorSubject
RxReplaySubject = require('rxjs/ReplaySubject').ReplaySubject

NewPlaceReview = require '../new_place_review'
NewAmenityReviewExtras = require '../new_amenity_review_extras'

module.exports = class NewAmenityReview extends NewPlaceReview
  NewPlaceReviewExtras: NewAmenityReviewExtras
  placeType: 'amenity'
  placeWithTabPath: 'amenityWithTab'

  constructor: ({@model}) ->
    @placeReviewModel = @model.amenityReview

    @reviewExtraFields = null

    super
