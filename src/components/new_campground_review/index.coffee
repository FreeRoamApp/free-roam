RxBehaviorSubject = require('rxjs/BehaviorSubject').BehaviorSubject
RxReplaySubject = require('rxjs/ReplaySubject').ReplaySubject

NewPlaceReview = require '../new_place_review'
NewCampgroundReviewExtras = require '../new_campground_review_extras'
NewCampgroundInitialInfo = require '../new_campground_initial_info'

module.exports = class NewCampground extends NewPlaceReview
  NewPlaceReviewExtras: NewCampgroundReviewExtras
  NewPlaceInitialInfo: NewCampgroundInitialInfo
  placeType: 'campground'

  constructor: ({@model}) ->
    @placeReviewModel = @model.campgroundReview

    @reviewExtraFields =
      crowds:
        isSeasonal: true
        valueStreams: new RxReplaySubject 1
        errorSubject: new RxBehaviorSubject null
      fullness:
        isSeasonal: true
        valueStreams: new RxReplaySubject 1
        errorSubject: new RxBehaviorSubject null
      noise:
        isDayNight: true
        valueStreams: new RxReplaySubject 1
        errorSubject: new RxBehaviorSubject null
      shade:
        valueStreams: new RxReplaySubject 1
        errorSubject: new RxBehaviorSubject null
      roadDifficulty:
        valueStreams: new RxReplaySubject 1
        errorSubject: new RxBehaviorSubject null
      cellSignal:
        valueStreams: new RxReplaySubject 1
        errorSubject: new RxBehaviorSubject null
      safety:
        valueStreams: new RxReplaySubject 1
        errorSubject: new RxBehaviorSubject null

    super
