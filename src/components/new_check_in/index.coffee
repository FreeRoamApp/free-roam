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

NewCheckInLocation = require '../new_check_in_location'
NewCheckInInfo = require '../new_check_in_info'
StepBar = require '../step_bar'
DateService = require '../../services/date'
colors = require '../../colors'
config = require '../../config'

if window?
  require './index.styl'

STEPS =
  checkInLocation: 0
  checkInInfo: 1

module.exports = class NewCheckIn
  constructor: ({@model, @router, @checkIn, trip}) ->
    @fields =
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
      attachments:
        valueStreams: new RxReplaySubject 1

    @resetValueStreams()

    @step = new RxBehaviorSubject 0
    @$stepBar = new StepBar {@model, @step}

    @$steps = _filter [
      new NewCheckInLocation {
        @model, @router, @fields, @step, @checkIn
      }
      new NewCheckInInfo {
        @model, @router, fields: @fields
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
      trip
      @checkIn
      sourceValue: @fields.source.valueStreams.switch()
      attachmentsValue: @fields.attachments.valueStreams.switch()
      nameValue: @fields.name.valueStreams.switch()
      startTimeValue: @fields.startTime.valueStreams.switch()
      endTimeValue: @fields.endTime.valueStreams.switch()
      isLoading: false
    }

  beforeUnmount: =>
    @step.next 0
    @resetValueStreams()

  resetValueStreams: =>
    today = DateService.format new Date(), 'yyyy-mm-dd'
    @fields.name.valueStreams.next @checkIn.map (checkIn) ->
      checkIn?.name or ''
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
    @fields.source.valueStreams.next @checkIn.map (checkIn) ->
      if checkIn
        {sourceId: checkIn.sourceId, sourceType: checkIn.sourceType}
      else
        {}

  upsert: =>
    {checkIn, trip, attachmentsValue, nameValue, sourceValue,
      startTimeValue, endTimeValue} = @state.getValue()

    @state.set isLoading: true

    if _find attachmentsValue, {isUploading: true}
      isReady = confirm @model.l.get 'newReview.pendingUpload'
    else
      isReady = true

    attachments = _filter attachmentsValue, ({isUploading}) -> not isUploading
    if isReady
      console.log 'upsert', checkIn
      @model.checkIn.upsert {
        tripIds: checkIn?.tripIds or [trip.id]
        setUserLocation: trip?.type is 'past'
        id: checkIn?.id
        attachments: attachments
        sourceId: sourceValue?.sourceId
        sourceType: sourceValue?.sourceType
        name: nameValue
        startTime: DateService.getLocalDateFromStr startTimeValue
        endTime: DateService.getLocalDateFromStr endTimeValue
      }
      .then (newCheckIn) =>
        @state.set isLoading: false
        @resetValueStreams()
        # TODO: not sure why timeout is necessary
        # w/o, map reloads
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

    z '.z-new-check-in',
      z @$steps[step]

      z @$stepBar, {
        isLoading: isLoading
        steps: @$steps.length
        isStepCompleted: @$steps[step]?.isCompleted?()
        save:
          icon: 'arrow-right'
          onclick: @upsert
      }
