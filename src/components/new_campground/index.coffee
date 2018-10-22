z = require 'zorium'
RxBehaviorSubject = require('rxjs/BehaviorSubject').BehaviorSubject
RxReplaySubject = require('rxjs/ReplaySubject').ReplaySubject
RxObservable = require('rxjs/Observable').Observable
require 'rxjs/add/observable/of'
require 'rxjs/add/observable/combineLatest'
_mapValues = require 'lodash/mapValues'
_isEmpty = require 'lodash/isEmpty'
_keys = require 'lodash/keys'
_defaults = require 'lodash/defaults'
_find = require 'lodash/find'
_filter = require 'lodash/filter'
_forEach = require 'lodash/forEach'
_map = require 'lodash/map'
_keys = require 'lodash/keys'
_zipObject = require 'lodash/zipObject'

AppBar = require '../../components/app_bar'
ButtonBack = require '../../components/button_back'
NewCampgroundInitialInfo = require '../new_campground_initial_info'
NewReviewCompose = require '../new_review_compose'
NewReviewExtras = require '../new_review_extras'
StepBar = require '../step_bar'
colors = require '../../colors'
config = require '../../config'

if window?
  require './index.styl'

# editing can probably be its own component. Editing just needs name, text fields, # of sites, and location
# auto-generated: cell, all sliders
# new campground is trying to source a lot more

# step 1 is add new campsite, then just go through review steps, but all are mandatory


module.exports = class NewCampground
  constructor: ({@model, @router}) ->
    me = @model.user.getMe()

    @$appBar = new AppBar {@model}
    @$buttonBack = new ButtonBack {@model, @router}

    @step = new RxBehaviorSubject 0
    @$stepBar = new StepBar {@model, @step}

    @season = new RxBehaviorSubject @model.time.getCurrentSeason()

    @reviewFields =
      titleValueStreams: new RxReplaySubject 1
      bodyValueStreams: new RxReplaySubject 1
      ratingValueStreams: new RxReplaySubject 1
      attachmentsValueStreams: new RxReplaySubject 1

    @fields =
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
      roadDifficulty:
        valueStreams: new RxReplaySubject 1
        errorSubject: new RxBehaviorSubject null
      cellSignal:
        valueStreams: new RxReplaySubject 1
        errorSubject: new RxBehaviorSubject null
      safety:
        valueStreams: new RxReplaySubject 1
        errorSubject: new RxBehaviorSubject null

    reviewExtraFieldsValues = RxObservable.combineLatest(
      _map @reviewExtraFields, ({valueStreams}) ->
        valueStreams.switch()
      (vals...) =>
        _zipObject _keys(@reviewExtraFields), vals
    )

    @resetValueStreams()

    @$steps = [
      new NewCampgroundInitialInfo {
        @model, @router, @fields, @season
      }
      new NewReviewExtras {
        @model, @router, fields: @reviewExtraFields,
        fieldsValues: reviewExtraFieldsValues, @season
      }
      new NewReviewCompose {
        @model, @router, fields: @reviewFields, @season
        uploadFn: (args...) ->
          @model['campgroundReview'].uploadImage.apply(
            @model['campgroundReview'].uploadImage
            args
          )
      }
    ]

    @state = z.state {
      @step
      isLoading: false
      titleValue: @reviewFields.titleValueStreams.switch()
      bodyValue: @reviewFields.bodyValueStreams.switch()
      attachmentsValue: @reviewFields.attachmentsValueStreams.switch()
      ratingValue: @reviewFields.ratingValueStreams.switch()
      reviewExtraFieldsValues
    }

  upsert: =>
    {attachmentsValue} = @state.getValue()

    if _find attachmentsValue, {isUploading: true}
      isReady = confirm @model.l.get 'newReview.pendingUpload'
    else
      isReady = true

    if isReady
      @state.set isLoading: true
      @model.campground.upsert {
        name: @fields.name.valueSubject.getValue()
        location: @fields.location.valueSubject.getValue()
        videos: @fields.videos.valueSubject.getValue()
      }
      .then @upsertReview
      .catch (err) =>
        console.log err
        # TODO: err messages
        @state.set isLoading: false
      .then =>
        @state.set isLoading: false

  upsertReview: (parent) =>
    {titleValue, bodyValue, ratingValue, attachmentsValue,
      reviewExtraFieldsValues} = @state.getValue()

    attachments = _filter attachmentsValue, ({isUploading}) -> not isUploading

    extras = _mapValues @reviewExtraFields, ({isSeasonal}, field) =>
      value = reviewExtraFieldsValues[field]
      if isSeasonal and value?
        season = @season.getValue()
        {"#{season}": value}
      else if not isSeasonal
        value

    @model.campgroundReview.upsert {
      type: 'campground'
      parentId: parent?.id
      title: titleValue
      body: bodyValue
      attachments: attachments
      rating: ratingValue
      extras: extras
    }
    .then (newReview) =>
      @resetValueStreams()

      # FIXME FIXME: rm HACK. for some reason thread is empty initially?
      # still unsure why
      setTimeout =>
        @router.go 'campgroundWithTab', {
          slug: parent?.slug, tab: 'reviews'
        }, {reset: true}
      , 200

  beforeUnmount: =>
    @step.next 0
    @resetValueStreams()

  resetValueStreams: =>
    @fields.name.valueSubject.next ''
    @fields.location.valueSubject.next ''
    @fields.videos.valueSubject.next []

    @reviewFields.titleValueStreams.next new RxBehaviorSubject ''
    @reviewFields.bodyValueStreams.next new RxBehaviorSubject ''
    @reviewFields.ratingValueStreams.next new RxBehaviorSubject null
    @reviewFields.attachmentsValueStreams.next new RxBehaviorSubject []
    _forEach @reviewExtraFields, (field) ->
      field.valueStreams.next new RxBehaviorSubject null

    @$steps?[1].reset()

  render: =>
    {step, isLoading} = @state.getValue()

    z '.z-new-campground',
      z @$appBar, {
        title: @$steps[step].getTitle()
        style: 'primary'
        $topLeftButton: z @$buttonBack
      }

      z @$steps[step]

      z @$stepBar, {
        isSaving: false
        steps: 3
        isStepCompleted: @$steps[step]?.isCompleted?()
        isLoading: isLoading
        save:
          icon: 'arrow-right'
          onclick: =>
            unless isLoading
              @upsert()
      }
