RxBehaviorSubject = require('rxjs/BehaviorSubject').BehaviorSubject
RxReplaySubject = require('rxjs/ReplaySubject').ReplaySubject

NewPlace = require '../new_place'
CampgroundNewReviewExtras = require '../new_campground_review_extras'
CampgroundNewReviewFeatures = require '../new_place_review_features'
NewCampgroundInitialInfo = require '../new_campground_initial_info'

module.exports = class NewCampground extends NewPlace
  NewReviewExtras: CampgroundNewReviewExtras
  NewReviewFeatures: CampgroundNewReviewFeatures
  NewPlaceInitialInfo: NewCampgroundInitialInfo
  type: 'campground'
  placeWithTabPath: 'campgroundWithTab'

  constructor: ({@model}) ->
    @placeModel = @model.campground
    @placeReviewModel = @model.campgroundReview

    @initialInfoFields =
      name:
        valueStreams: new RxReplaySubject 1
        errorSubject: new RxBehaviorSubject null
      details:
        valueStreams: new RxReplaySubject 1
        errorSubject: new RxBehaviorSubject null
      website:
        valueStreams: new RxReplaySubject 1
        errorSubject: new RxBehaviorSubject null
      location:
        valueStreams: new RxReplaySubject 1
        errorSubject: new RxBehaviorSubject null
      subType:
        valueStreams: new RxReplaySubject 1
        errorSubject: new RxBehaviorSubject null
      agency:
        valueStreams: new RxReplaySubject 1
        errorSubject: new RxBehaviorSubject null
      region:
        valueStreams: new RxReplaySubject 1
        errorSubject: new RxBehaviorSubject null
      office:
        valueStreams: new RxReplaySubject 1
        errorSubject: new RxBehaviorSubject null
      features:
        valueStreams: new RxReplaySubject 1
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

    @reviewFeaturesFields =
      features:
        valueStreams: new RxReplaySubject 1
        errorSubject: new RxBehaviorSubject null

    super
