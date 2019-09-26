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
_isEmpty = require 'lodash/isEmpty'
_keys = require 'lodash/keys'
_merge = require 'lodash/merge'
_reduce = require 'lodash/reduce'
_values = require 'lodash/values'
_zipObject = require 'lodash/zipObject'

ReviewThanksDialog = require '../review_thanks_dialog'
NewReviewCompose = require '../new_review_compose'
StepBar = require '../step_bar'
colors = require '../../colors'
config = require '../../config'

if window?
  require './index.styl'

STEPS =
  review: 0
  reviewExtra: 1

AUTOSAVE_FREQ_MS = 3000 # every 3 seconds
LOCAL_STORAGE_AUTOSAVE = 'newReview:autosave'

module.exports = class NewPlaceReview
  constructor: ({@model, @router, @review, @parent}) ->
    me = @model.user.getMe()

    @season = new RxBehaviorSubject @model.time.getCurrentSeason()

    @reviewFields =
      title:
        valueStreams: new RxReplaySubject 1
        errorSubject: new RxBehaviorSubject null
      body:
        valueStreams: new RxReplaySubject 1
        errorSubject: new RxBehaviorSubject null
      rating:
        valueStreams: new RxReplaySubject 1
        errorSubject: new RxBehaviorSubject null
      attachments:
        valueStreams: new RxReplaySubject 1
        errorSubject: new RxBehaviorSubject null

    reviewExtraFieldsValues = RxObservable.combineLatest(
      _map @reviewExtraFields, ({valueStreams}) ->
        valueStreams.switch()
      (vals...) =>
        _zipObject _keys(@reviewExtraFields), vals
    )

    @resetValueStreams()

    @step = new RxBehaviorSubject 0
    @$stepBar = new StepBar {@model, @step}

    @$reviewThanksDialog = new ReviewThanksDialog {@model}

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
          @model, @router, @parent, fields: @reviewExtraFields,
          fieldsValues: reviewExtraFieldsValues, @season
          isOptional: true
        }
    ]

    @state = z.state {
      @step
      me: @model.user.getMe()
      titleValue: @reviewFields.title.valueStreams.switch()
      bodyValue: @reviewFields.body.valueStreams.switch()
      attachmentsValue: @reviewFields.attachments.valueStreams.switch()
      ratingValue: @reviewFields.rating.valueStreams.switch()
      reviewExtraFieldsValues
      review: @review
      parent: @parent
      isLoading: false
    }

  afterMount: =>
    changesStream = @getAllChangesStream()
    changesStreamAndParent = RxObservable.combineLatest(
      changesStream, @parent, (vals...) -> vals
    )
    @disposable = changesStreamAndParent.auditTime(AUTOSAVE_FREQ_MS)
    .subscribe ([fields, parent]) ->
      key = LOCAL_STORAGE_AUTOSAVE + ':' + parent.id
      localStorage[key] = JSON.stringify fields

  beforeUnmount: =>
    @step.next 0
    @resetValueStreams()
    @disposable.unsubscribe()

  resetValueStreams: =>
    saved = RxObservable.combineLatest(
      @parent.map (parent) ->
        autosave = try
          key = LOCAL_STORAGE_AUTOSAVE + ':' + parent.id
          JSON.parse localStorage[key]
        catch
          {}

      @review or RxObservable.of null
    )

    # if @review
    @reviewFields.title.valueStreams.next saved.map ([autosave, review]) ->
      autosave['review.title'] or review?.title or ''
    @reviewFields.body.valueStreams.next saved.map ([autosave, review]) ->
      autosave['review.body'] or review?.body or ''
    @reviewFields.rating.valueStreams.next saved.map ([autosave, review]) ->
      autosave['review.rating'] or review?.rating
    @reviewFields.attachments.valueStreams.next saved.map ([autosave, review]) ->
      autosave['review.attachments'] or review?.attachments or []

    # TODO!
    _forEach @reviewExtraFields, (field, key) =>
      {isSeasonal, isDayNight} = field
      field.valueStreams.next saved.map ([autosave, review]) ->
        value = review?.extras?[key]
        if isSeasonal or isDayNight
          value = _first _values(value)
        value
    # else
    #   @reviewFields.title.valueStreams.next new RxBehaviorSubject ''
    #   @reviewFields.body.valueStreams.next new RxBehaviorSubject ''
    #   @reviewFields.rating.valueStreams.next new RxBehaviorSubject null
    #   @reviewFields.attachments.valueStreams.next new RxBehaviorSubject []
    #   _forEach @reviewExtraFields, (field) ->
    #     field.valueStreams.next new RxBehaviorSubject null

  getAllChangesStream: =>
    initialInfo = @getChangesStream @initialInfoFields, 'initialInfo'
    review = @getChangesStream @reviewFields, 'review'
    reviewExtra = @getChangesStream @reviewExtraFields, 'reviewExtra'
    allChanges = _merge initialInfo, review, reviewExtra
    keys = _keys allChanges

    RxObservable.combineLatest(
      _values allChanges
      (vals...) ->
        _zipObject keys, vals
    )

  getChangesStream: (fields, typeKey) =>
    observables = _reduce fields, (obj, field, key) ->
      if field.valueStreams
        obj["#{typeKey}.#{key}"] = field.valueStreams.switch()
      else
        obj["#{typeKey}.#{key}"] = field.valueSubject
      obj
    , {}

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
          delete localStorage[LOCAL_STORAGE_AUTOSAVE + ':' + parent?.id]
          @resetValueStreams()
          # FIXME FIXME: rm HACK. for some reason thread is empty initially?
          # still unsure why
          setTimeout =>
            @router.go @placeWithTabPath, {
              slug: parent?.slug, tab: 'reviews'
            }, {reset: true}
            @model.overlay.open @$reviewThanksDialog
          , 200
        .catch (err) =>
          console.log 'err', err
          err = try
            JSON.parse err.message
          catch
            {}
          @step.next STEPS[err.info?.step] or 0
          errorSubject = switch err.info.field
            when 'body' then @reviewFields.body.errorSubject
            else @reviewFields.body.errorSubject
          errorSubject.next @model.l.get err.info.langKey

          @state.set isLoading: false
      else
        @state.set isLoading: false


  render: =>
    {step, isLoading, review, attachmentsValue} = @state.getValue()

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
