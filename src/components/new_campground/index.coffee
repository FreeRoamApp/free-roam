RxBehaviorSubject = require('rxjs/BehaviorSubject').BehaviorSubject
RxReplaySubject = require('rxjs/ReplaySubject').ReplaySubject

NewPlace = require '../new_place'
CampgroundNewReviewExtras = require '../new_campground_review_extras'
NewCampgroundInitialInfo = require '../new_campground_initial_info'

module.exports = class NewCampground extends NewPlace
  NewReviewExtras: CampgroundNewReviewExtras
  NewPlaceInitialInfo: NewCampgroundInitialInfo
  type: 'campground'
  placeWithTabPath: 'campgroundWithTab'

  constructor: ({@model}) ->
    @placeModel = @model.campground
    @placeReviewModel = @model.campgroundReview

    @initialInfoFields =
      name:
        valueSubject: new RxBehaviorSubject ''
        errorSubject: new RxBehaviorSubject null
      location:
        valueSubject: new RxBehaviorSubject ''
        errorSubject: new RxBehaviorSubject null
      videos:
        valueSubject: new RxBehaviorSubject []
        errorSubject: new RxBehaviorSubject null

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
      cleanliness:
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
      pricePaid:
        valueStreams: new RxReplaySubject 1
        errorSubject: new RxBehaviorSubject null

    super
