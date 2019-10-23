z = require 'zorium'
RxBehaviorSubject = require('rxjs/BehaviorSubject').BehaviorSubject
RxReplaySubject = require('rxjs/ReplaySubject').ReplaySubject
RxObservable = require('rxjs/Observable').Observable
_filter = require 'lodash/filter'
_find = require 'lodash/find'

PrimaryInput = require '../primary_input'
UploadImagesList = require '../upload_images_list'
MarkdownEditor = require '../markdown_editor'
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

module.exports = class NewCheckInInfo
  constructor: ({@model, @router, @checkIn, @fields}) ->
    me = @model.user.getMe()

    @$nameInput = new PrimaryInput
      valueStreams: @fields.name.valueStreams
      error: @fields.name.errorSubject

    @$startTimeInput = new PrimaryInput
      valueStreams: @fields.startTime.valueStreams
      error: @fields.startTime.errorSubject

    @$endTimeInput = new PrimaryInput
      valueStreams: @fields.endTime.valueStreams
      error: @fields.endTime.errorSubject

    @$markdownEditor = new MarkdownEditor {
      @model
      valueStreams: @fields.notes.valueStreams
    }

    @$uploadImagesList = new UploadImagesList {
      @model, @router, attachmentsValueStreams: @fields.attachments.valueStreams
      requestTags: false, requestLocation: false
      uploadFn: (args...) =>
        @model.checkIn.uploadImage.apply(
          @model.checkIn.uploadImage
          args
        )
    }

    # @state = z.state {}

  isCompleted: ->
    true

  render: =>
    # {} = @state.getValue()

    z '.z-edit-check-in',
      z '.g-grid',
        z '.field',
          z '.input',
            z @$nameInput,
              hintText: @model.l.get 'editCheckIn.namePlaceholder'

        z '.field.flex',
          z '.input',
            z @$startTimeInput,
              type: 'date'
              hintText: @model.l.get 'editCheckIn.startTimePlaceholder'

          z '.input.left-auto',
            z @$endTimeInput,
              type: 'date'
              hintText: @model.l.get 'editCheckIn.endTimePlaceholder'

        z '.notes',
          z '.title', @model.l.get 'editCheckIn.notes'
          z '.editor',
            z @$markdownEditor,
              imagesAllowed: false
              hintText: @model.l.get 'editCheckIn.notesHintText'


        z @$uploadImagesList
