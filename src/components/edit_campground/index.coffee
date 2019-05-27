RxBehaviorSubject = require('rxjs/BehaviorSubject').BehaviorSubject
RxReplaySubject = require('rxjs/ReplaySubject').ReplaySubject

EditPlace = require '../edit_place'
NewCampgroundInitialInfo = require '../new_campground_initial_info'

module.exports = class EditPlace extends EditPlace
  NewPlaceInitialInfo: NewCampgroundInitialInfo

  constructor: ({@model}) ->
    @placeModel = @model.campground

    @initialInfoFields =
      name:
        valueStreams: new RxReplaySubject 1
        errorSubject: new RxBehaviorSubject null
      details:
        valueStreams: new RxReplaySubject 1
        errorSubject: new RxBehaviorSubject null
      location:
        valueStreams: new RxReplaySubject 1
        errorSubject: new RxBehaviorSubject null

    super
