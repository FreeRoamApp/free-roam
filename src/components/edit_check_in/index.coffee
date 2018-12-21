z = require 'zorium'
RxBehaviorSubject = require('rxjs/BehaviorSubject').BehaviorSubject
RxReplaySubject = require('rxjs/ReplaySubject').ReplaySubject
RxObservable = require('rxjs/Observable').Observable
_filter = require 'lodash/filter'
_find = require 'lodash/find'

PrimaryInput = require '../primary_input'
PrimaryButton = require '../primary_button'
CoordinatePicker = require '../coordinate_picker'
UploadImagesList = require '../upload_images_list'
Icon = require '../icon'
DateService = require '../../services/date'
colors = require '../../colors'
config = require '../../config'

if window?
  require './index.styl'

###
Location (use place_search), photos

Is this a campground?

Want to help us help others? Add a little more info about this campground so
others can find it
###

getLocalDateFromStr = (str) ->
  if str
    arr = str.split '-'
    new Date arr[0], arr[1], arr[2]
  else
    null


module.exports = class EditCheckIn
  constructor: ({@model, @router, @checkIn}) ->
    me = @model.user.getMe()

    @fields =
      # location:
      #   valueStreams: new RxReplaySubject 1
      #   errorSubject: new RxBehaviorSubject null
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

    @$nameInput = new PrimaryInput
      valueStreams: @fields.name.valueStreams
      error: @fields.name.errorSubject

    # @$locationInput = new PrimaryInput
    #   valueStreams: @fields.location.valueStreams
    #   error: @fields.location.errorSubject

    @$startTimeInput = new PrimaryInput
      valueStreams: @fields.startTime.valueStreams
      error: @fields.startTime.errorSubject

    @$endTimeInput = new PrimaryInput
      valueStreams: @fields.endTime.valueStreams
      error: @fields.endTime.errorSubject

    @$saveButton = new PrimaryButton()

    @$uploadImagesList = new UploadImagesList {
      @model, @router, attachmentsValueStreams: @fields.attachments.valueStreams
      requestTags: false, requestLocation: false
      uploadFn: (args...) =>
        @model.checkIn.uploadImage.apply(
          @model.checkIn.uploadImage
          args
        )
    }

    @state = z.state {
      checkIn: @checkIn
      isSaving: false
      attachmentsValue: @fields.attachments.valueStreams.switch()
      nameValue: @fields.name.valueStreams.switch()
      startTimeValue: @fields.startTime.valueStreams.switch()
      endTimeValue: @fields.endTime.valueStreams.switch()
    }

  upsert: =>
    {checkIn, attachmentsValue, nameValue,
      startTimeValue, endTimeValue} = @state.getValue()

    @state.set isLoading: true

    if _find attachmentsValue, {isUploading: true}
      isReady = confirm @model.l.get 'newReview.pendingUpload'
    else
      isReady = true

    attachments = _filter attachmentsValue, ({isUploading}) -> not isUploading
    if isReady
      @model.checkIn.upsert {
        id: checkIn?.id
        attachments: attachments
        name: nameValue
        startTime: getLocalDateFromStr startTimeValue
        endTime: getLocalDateFromStr endTimeValue
      }
      .then (newCheckIn) =>
        @state.set isLoading: false
        @resetValueStreams()
        @router.back()
      .catch (err) =>
        console.log 'upload err', err
        @state.set isLoading: false

  resetValueStreams: =>
    if @checkIn
      @fields.name.valueStreams.next @checkIn.map (checkIn) ->
        checkIn?.name
      @fields.startTime.valueStreams.next @checkIn.map (checkIn) ->
        if checkIn?.startTime
          DateService.format new Date(checkIn?.startTime), 'yyyy-mm-dd'
        else
          ''
      @fields.endTime.valueStreams.next @checkIn.map (checkIn) ->
        if checkIn?.endTime
          DateService.format new Date(checkIn?.endTime), 'yyyy-mm-dd'
        else
          ''
      @fields.attachments.valueStreams.next @checkIn.map (checkIn) ->
        checkIn?.attachments
    else
      @fields.name.valueStreams.next new RxBehaviorSubject ''
      @fields.attachments.valueStreams.next new RxBehaviorSubject []

  render: =>
    {isSaving} = @state.getValue()

    z '.z-edit-check-in',
      z '.g-grid',
        z '.field',
          z '.input',
            z @$nameInput,
              hintText: @model.l.get 'editCheckIn.namePlaceholder'

        z '.field',
          z '.input',
            z @$startTimeInput,
              type: 'date'
              hintText: @model.l.get 'editCheckIn.startTimePlaceholder'

        z '.field',
          z '.input',
            z @$endTimeInput,
              type: 'date'
              hintText: @model.l.get 'editCheckIn.endTimePlaceholder'

          z @$uploadImagesList
          z @$saveButton,
            text: if isSaving \
                  then @model.l.get 'general.saving'
                  else @model.l.get 'general.save'
            onclick: @upsert
        # z 'label.field.where',
        #   z '.name', @model.l.get 'newPlaceInitialInfo.where'
        #   z '.form',
        #     z '.input',
        #       z @$locationInput,
        #         hintText: @model.l.get 'newPlaceInitialInfo.coordinates'
        #     z '.button',
        #       z @$mapButton,
        #         text: @model.l.get 'newPlaceInitialInfo.coordinatesFromMap'
        #         isFullWidth: false
        #         onclick: =>
        #           @model.overlay.open new CoordinatePicker {
        #             @model, @router, coordinates: @fields.location.valueStreams
        #           }
