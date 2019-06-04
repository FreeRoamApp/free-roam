RxBehaviorSubject = require('rxjs/BehaviorSubject').BehaviorSubject
RxReplaySubject = require('rxjs/ReplaySubject').ReplaySubject

EditPlace = require '../edit_place'
NewOvernightInitialInfo = require '../new_overnight_initial_info'

module.exports = class EditPlace extends EditPlace
  NewPlaceInitialInfo: NewOvernightInitialInfo

  constructor: ({@model}) ->
    @placeModel = @model.overnight

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
      subType:
        valueStreams: new RxReplaySubject 1
        errorSubject: new RxBehaviorSubject null

    super
