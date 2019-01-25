z = require 'zorium'
RxBehaviorSubject = require('rxjs/BehaviorSubject').BehaviorSubject
RxReplaySubject = require('rxjs/ReplaySubject').ReplaySubject
RxObservable = require('rxjs/Observable').Observable
require 'rxjs/add/observable/of'
require 'rxjs/add/observable/combineLatest'
require 'rxjs/add/operator/switch'
require 'rxjs/add/operator/switchMap'
require 'rxjs/add/operator/map'
_defaults = require 'lodash/defaults'
_find = require 'lodash/find'
_filter = require 'lodash/filter'
_first = require 'lodash/first'
_mapValues = require 'lodash/mapValues'
_forEach = require 'lodash/forEach'
_map = require 'lodash/map'
_keys = require 'lodash/keys'
_values = require 'lodash/values'
_zipObject = require 'lodash/zipObject'

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


module.exports = class NewPlaceReview
  constructor: ({@model, @router, @review, parent}) ->
    me = @model.user.getMe()

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

    @step = new RxBehaviorSubject 0
    @$stepBar = new StepBar {@model, @step}

    @$steps = _filter [
      new NewReviewCompose {
        @model, @router, fields: @reviewFields, @season
        uploadFn: (args...) =>
          @placeReviewModel.uploadImage.apply(
            @placeReviewModel.uploadImage
            args
          )
      }
      if @reviewExtraFields
        new @NewPlaceReviewExtras {
          @model, @router, fields: @reviewExtraFields,
          fieldsValues: reviewExtraFieldsValues, @season
          isOptional: true
        }
    ]

    @state = z.state {
      @step
      me: @model.user.getMe()
      titleValue: @reviewFields.titleValueStreams.switch()
      bodyValue: @reviewFields.bodyValueStreams.switch()
      attachmentsValue: @reviewFields.attachmentsValueStreams.switch()
      ratingValue: @reviewFields.ratingValueStreams.switch()
      reviewExtraFieldsValues
      review: @review
      parent: parent
      isLoading: false
    }

  beforeUnmount: =>
    @step.next 0
    @resetValueStreams()

  resetValueStreams: =>
    if @review
      @reviewFields.titleValueStreams.next @review.map (review) ->
        review?.title or ''
      @reviewFields.bodyValueStreams.next @review.map (review) ->
        review?.body or ''
      @reviewFields.ratingValueStreams.next @review.map (review) ->
        review?.rating
      @reviewFields.attachmentsValueStreams.next @review.map (review) ->
        review?.attachments
      _forEach @reviewExtraFields, (field, key) =>
        {isSeasonal, isDayNight} = field
        field.valueStreams.next @review.map (review) ->
          value = review?.extras?[key]
          if isSeasonal or isDayNight
            value = _first _values(value)
          value
    else
      @reviewFields.titleValueStreams.next new RxBehaviorSubject ''
      @reviewFields.bodyValueStreams.next new RxBehaviorSubject ''
      @reviewFields.ratingValueStreams.next new RxBehaviorSubject null
      @reviewFields.attachmentsValueStreams.next new RxBehaviorSubject []
      _forEach @reviewExtraFields, (field) ->
        field.valueStreams.next new RxBehaviorSubject null

  upsert: (e) =>
    {me, reviewExtraFieldsValues, titleValue, bodyValue, ratingValue,
      attachmentsValue, review, parent} = @state.getValue()
    @state.set isLoading: true
    @model.user.requestLoginIfGuest me
    .then =>
      if _find attachmentsValue, {isUploading: true}
        isReady = confirm @model.l.get 'newReview.pendingUpload'
      else
        isReady = true

      attachments = _filter attachmentsValue, ({isUploading}) -> not isUploading

      extras = _mapValues @reviewExtraFields, ({isSeasonal}, field) =>
        value = reviewExtraFieldsValues[field]
        if isSeasonal and value?
          season = @season.getValue()
          {"#{season}": value}
        else if not isSeasonal
          value

      if isReady
        @placeReviewModel.upsert {
          id: review?.id
          type: review?.type or @placeType
          parentId: parent?.id
          title: titleValue
          body: bodyValue
          attachments: attachments
          rating: ratingValue
          extras: extras
        }
        .then (newReview) =>
          @state.set isLoading: false
          @resetValueStreams()
          # FIXME FIXME: rm HACK. for some reason thread is empty initially?
          # still unsure why
          setTimeout =>
            @router.go @placeWithTabPath, {
              slug: parent?.slug, tab: 'reviews'
            }, {reset: true}
          , 200
    .catch (err) =>
      console.log 'upload err', err
      @state.set isLoading: false


  render: =>
    {step, isLoading, review} = @state.getValue()

    z '.z-new-place-review',
      z @$steps[step]

      z @$stepBar, {
        isLoading: isLoading
        steps: @$steps.length
        isStepCompleted: @$steps[step]?.isCompleted?()
        save:
          icon: 'arrow-right'
          onclick: @upsert
      }
