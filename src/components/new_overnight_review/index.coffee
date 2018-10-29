RxBehaviorSubject = require('rxjs/BehaviorSubject').BehaviorSubject
RxReplaySubject = require('rxjs/ReplaySubject').ReplaySubject

NewPlaceReview = require '../new_place_review'
NewOvernightReviewExtras = require '../new_overnight_review_extras'

module.exports = class NewOvernightReview extends NewPlaceReview
  NewPlaceReviewExtras: NewOvernightReviewExtras
  placeType: 'overnight'
  placeWithTabPath: 'overnightWithTab'

  constructor: ({@model}) ->
    @placeReviewModel = @model.overnightReview

    @reviewExtraFields =
      noise:
        isDayNight: true
        valueStreams: new RxReplaySubject 1
        errorSubject: new RxBehaviorSubject null
      cellSignal:
        valueStreams: new RxReplaySubject 1
        errorSubject: new RxBehaviorSubject null
      safety:
        valueStreams: new RxReplaySubject 1
        errorSubject: new RxBehaviorSubject null

    super
