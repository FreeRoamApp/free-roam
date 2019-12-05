z = require 'zorium'
RxBehaviorSubject = require('rxjs/BehaviorSubject').BehaviorSubject
RxReplaySubject = require('rxjs/ReplaySubject').ReplaySubject
RxObservable = require('rxjs/Observable').Observable
require 'rxjs/add/observable/of'
require 'rxjs/add/observable/combineLatest'
require 'rxjs/add/operator/switch'
require 'rxjs/add/operator/map'
_find = require 'lodash/find'
_filter = require 'lodash/filter'

ActionBar = require '../action_bar'
NewCheckInChooseTrip = require '../new_check_in_choose_trip'
NewCheckInInfo = require '../new_check_in_info'
StepBar = require '../step_bar'
DateService = require '../../services/date'
colors = require '../../colors'
config = require '../../config'

if window?
  require './index.styl'

STEPS =
  chooseTrip: 0
  checkInInfo: 1

module.exports = class NewCheckIn
  constructor: (options) ->
    {@model, @router, @checkIn, @trip, @place, @step, @isOverlay
    skipChooseTrip} = options

    @checkIn ?= RxObservable.of null
    @trip ?= RxObservable.of null
    @place ?= RxObservable.of null

    @fields =
      tripId:
        valueStreams: new RxReplaySubject 1
      source:
        valueStreams: new RxReplaySubject 1
      name:
        valueStreams: new RxReplaySubject 1
        errorSubject: new RxBehaviorSubject null
      startTime:
        valueStreams: new RxReplaySubject 1
        errorSubject: new RxBehaviorSubject null
      endTime:
        valueStreams: new RxReplaySubject 1
        errorSubject: new RxBehaviorSubject null
      notes:
        valueStreams: new RxReplaySubject 1
        errorSubject: new RxBehaviorSubject null
      attachments:
        valueStreams: new RxReplaySubject 1

    @checkInAndTrip = RxObservable.combineLatest(
      @checkIn, @trip, (vals...) -> vals
    )

    @checkInAndPlace = RxObservable.combineLatest(
      @checkIn, @place, (vals...) -> vals
    )

    @resetValueStreams()

    @$actionBar = new ActionBar {@model}

    @step ?= new RxBehaviorSubject 0
    @initialStepValue = @step.getValue()
    @$stepBar = new StepBar {@model, @step}

    @$steps = _filter [
      unless skipChooseTrip
        new NewCheckInChooseTrip {
          @model, @router, @fields, @trip
        }
      new NewCheckInInfo {
        @model, @router, @fields
        uploadFn: (args...) =>
          @checkInModel.uploadImage.apply(
            @checkInModel.uploadImage
            args
          )
      }
    ]

    @state = z.state {
      @step
      me: @model.user.getMe()
      @trip
      @checkIn
      @place
      tripIdValue: @fields.tripId.valueStreams.switch()
      sourceValue: @fields.source.valueStreams.switch()
      attachmentsValue: @fields.attachments.valueStreams.switch()
      nameValue: @fields.name.valueStreams.switch()
      notesValue: @fields.notes.valueStreams.switch()
      startTimeValue: @fields.startTime.valueStreams.switch()
      endTimeValue: @fields.endTime.valueStreams.switch()
      isLoading: false
    }

  beforeUnmount: =>
    @step.next @initialStepValue
    @resetValueStreams()

  resetValueStreams: =>
    today = DateService.format new Date(), 'yyyy-mm-dd'
    @fields.tripId.valueStreams.next @checkInAndTrip.map ([checkIn, trip]) ->
      checkIn?.tripIds?[0] or trip?.id or null
    @fields.name.valueStreams.next @checkInAndPlace.map ([checkIn, place]) ->
      checkIn?.name or place?.name or ''
    @fields.startTime.valueStreams.next @checkIn.map (checkIn) ->
      if checkIn?.startTime
        DateService.format new Date(checkIn?.startTime), 'yyyy-mm-dd'
      else
        today
    @fields.endTime.valueStreams.next @checkIn.map (checkIn) ->
      if checkIn?.endTime
        DateService.format new Date(checkIn?.endTime), 'yyyy-mm-dd'
      else
        today
    @fields.attachments.valueStreams.next @checkIn.map (checkIn) ->
      checkIn?.attachments or []
    @fields.notes.valueStreams.next @checkIn.map (checkIn) ->
      checkIn?.notes or ''
    @fields.source.valueStreams.next @checkInAndPlace.map ([checkIn, place]) ->
      if checkIn
        {sourceId: checkIn.sourceId, sourceType: checkIn.sourceType}
      else if place
        {sourceId: place.id, sourceType: place.type}
      else
        {}

  upsert: =>
    {checkIn, trip, tripIdValue, attachmentsValue, nameValue, sourceValue,
      place, notesValue, startTimeValue, endTimeValue} = @state.getValue()

    @state.set isLoading: true

    if _find attachmentsValue, {isUploading: true}
      isReady = confirm @model.l.get 'newReview.pendingUpload'
    else
      isReady = true

    attachments = _filter attachmentsValue, ({isUploading}) -> not isUploading
    if isReady
      tripId = tripIdValue or trip?.id

      (if sourceValue?.sourceType is 'coordinate' and not sourceValue?.sourceId
        @model.coordinate.upsert {
          name: nameValue
          location: place.location
        }, {invalidateAll: false}
      else
        Promise.resolve {id: sourceValue.sourceId}
      ).then ({id}) =>
        if checkIn?
          ga? 'send', 'event', 'trip', 'updateDestination', trip?.id
        else
          ga? 'send', 'event', 'trip', 'addDestination', trip?.id
        @model.checkIn.upsert {
          tripIds: if tripId then [tripId] else checkIn?.tripIds
          setUserLocation: false # trip?.type is 'past'
          id: checkIn?.id
          attachments: attachments
          sourceId: id
          sourceType: sourceValue?.sourceType
          name: nameValue
          notes: notesValue
          startTime: DateService.getLocalDateFromStr startTimeValue
          endTime: DateService.getLocalDateFromStr endTimeValue
        }
      .then (newCheckIn) =>
        @state.set isLoading: false
        @resetValueStreams()
        # TODO: not sure why timeout is necessary
        # w/o, map reloads
        if @isOverlay
          @model.overlay.close()
        else
          setTimeout =>
            @router.back()
            # @router.go 'tripByType', {
            #   type: trip.type
            # }, {reset: true}
          , 0
      .catch (err) =>
        console.log 'upload err', err
        @state.set isLoading: false

  render: =>
    {step, isLoading, checkIn, attachmentsValue, trip} = @state.getValue()

    z '.z-new-check-in', {
      className: z.classKebab {@isOverlay}
    },
      unless checkIn?.id
        z @$actionBar, {
          isSecondary: true
          isSaving: isLoading
          cancel:
            text: @model.l.get 'general.discard'
            onclick: =>
              @router.back()
          save:
            if @$steps.length is 1
              {
                text: @model.l.get 'general.done'
                onclick: @upsert
              }
        }
      z @$steps[step]

      if @$steps.length > 1
        z @$stepBar, {
          isLoading: isLoading
          steps: @$steps.length
          isStepCompleted: @$steps[step]?.isCompleted?()
          save:
            icon: 'arrow-right'
            onclick: @upsert
        }
