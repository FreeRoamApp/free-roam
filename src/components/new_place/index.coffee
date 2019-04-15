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
NewReviewCompose = require '../new_review_compose'

StepBar = require '../step_bar'
colors = require '../../colors'
config = require '../../config'

if window?
  require './index.styl'

# editing can probably be its own component. Editing just needs name, text fields, # of sites, and location
# auto-generated: cell, all sliders
# new campground is trying to source a lot more

# step 1 is add new campsite, then just go through review steps, but all are mandatory


module.exports = class NewPlace
  constructor: ({@model, @router, @location}) ->
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

    reviewExtraFieldsValues = RxObservable.combineLatest(
      _map @reviewExtraFields, ({valueStreams}) ->
        valueStreams.switch()
      (vals...) =>
        _zipObject _keys(@reviewExtraFields), vals
    )

    @resetValueStreams()

    @$steps = [
      new @NewPlaceInitialInfo {
        @model, @router, fields: @initialInfoFields, @season
      }
      new @NewReviewExtras {
        @model, @router, fields: @reviewExtraFields,
        fieldsValues: reviewExtraFieldsValues, @season
      }
      new NewReviewCompose {
        @model, @router, fields: @reviewFields, @season
        uploadFn: (args...) =>
          @placeReviewModel.uploadImage.apply(
            @placeReviewModel.uploadImage
            args
          )
      }
    ]

    @state = z.state {
      @step
      me: @model.user.getMe()
      isLoading: false
      locationValue: @initialInfoFields.location.valueStreams.switch()
      titleValue: @reviewFields.titleValueStreams.switch()
      bodyValue: @reviewFields.bodyValueStreams.switch()
      attachmentsValue: @reviewFields.attachmentsValueStreams.switch()
      ratingValue: @reviewFields.ratingValueStreams.switch()
      reviewExtraFieldsValues
    }

  upsert: =>
    {me, locationValue, attachmentsValue} = @state.getValue()

    @state.set isLoading: true

    @model.user.requestLoginIfGuest me
    .then =>
      if _find attachmentsValue, {isUploading: true}
        isReady = confirm @model.l.get 'newReview.pendingUpload'
      else
        isReady = true

      if isReady
        @placeModel.upsert {
          name: @initialInfoFields.name.valueSubject.getValue()
          location: locationValue
          subType: @initialInfoFields.subType?.valueSubject.getValue()
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

    @placeReviewModel.upsert {
      type: @type
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
        @router.go @placeWithTabPath, {
          slug: parent?.slug, tab: 'reviews'
        }, {reset: true}
      , 200

  beforeUnmount: =>
    @step.next 0
    @resetValueStreams()

  resetValueStreams: =>
    @initialInfoFields.name.valueSubject.next ''
    @initialInfoFields.details.valueSubject.next ''

    @initialInfoFields.location.valueStreams.next @location

    @reviewFields.titleValueStreams.next new RxBehaviorSubject ''
    @reviewFields.bodyValueStreams.next new RxBehaviorSubject ''
    @reviewFields.ratingValueStreams.next new RxBehaviorSubject null
    @reviewFields.attachmentsValueStreams.next new RxBehaviorSubject []
    _forEach @reviewExtraFields, (field) ->
      field.valueStreams.next new RxBehaviorSubject null

    @$steps?[1].reset()

  render: =>
    {step, isLoading, locationValue} = @state.getValue()

    z '.z-new-place',
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
