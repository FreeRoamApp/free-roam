RxBehaviorSubject = require('rxjs/BehaviorSubject').BehaviorSubject
RxReplaySubject = require('rxjs/ReplaySubject').ReplaySubject

NewPlace = require '../new_place'
OvernightNewReviewExtras = require '../new_overnight_review_extras'
NewOvernightInitialInfo = require '../new_overnight_initial_info'

module.exports = class NewOvernight extends NewPlace
  NewReviewExtras: OvernightNewReviewExtras
  NewPlaceInitialInfo: NewOvernightInitialInfo
  type: 'overnight'
  placeWithTabPath: 'overnightWithTab'

  constructor: ({@model}) ->
    @placeModel = @model.overnight
    @placeReviewModel = @model.overnightReview

    @initialInfoFields =
      name:
        valueStreams: new RxReplaySubject ''
        errorSubject: new RxBehaviorSubject null
      details:
        valueStreams: new RxReplaySubject ''
        errorSubject: new RxBehaviorSubject null
      location:
        valueStreams: new RxReplaySubject 1
        errorSubject: new RxBehaviorSubject null
      subType:
        valueStreams: new RxReplaySubject 1
        errorSubject: new RxBehaviorSubject null

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
