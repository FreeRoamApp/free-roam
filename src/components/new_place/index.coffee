z = require 'zorium'
RxBehaviorSubject = require('rxjs/BehaviorSubject').BehaviorSubject
RxReplaySubject = require('rxjs/ReplaySubject').ReplaySubject
RxObservable = require('rxjs/Observable').Observable
require 'rxjs/add/observable/of'
require 'rxjs/add/observable/combineLatest'
require 'rxjs/add/operator/auditTime'
_mapValues = require 'lodash/mapValues'
_isEmpty = require 'lodash/isEmpty'
_keys = require 'lodash/keys'
_values = require 'lodash/values'
_defaults = require 'lodash/defaults'
_find = require 'lodash/find'
_filter = require 'lodash/filter'
_forEach = require 'lodash/forEach'
_map = require 'lodash/map'
_merge = require 'lodash/merge'
_reduce = require 'lodash/reduce'
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

# TODO: combine code here with new_place_review/index.coffee (a lot of overlap)

STEPS =
  initialInfo: 0
  reviewExtra: 1
  review: 2

AUTOSAVE_FREQ_MS = 3000 # every 3 seconds
LOCAL_STORAGE_AUTOSAVE = 'newPlace:autosave'

module.exports = class NewPlace
  constructor: ({@model, @router, @location}) ->
    me = @model.user.getMe()

    @$appBar = new AppBar {@model}
    @$buttonBack = new ButtonBack {@model, @router}

    @step = new RxBehaviorSubject 0
    @$stepBar = new StepBar {@model, @step}

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

    reviewFeaturesFieldsValues = RxObservable.combineLatest(
      _map @reviewFeaturesFields, ({valueStreams}) ->
        valueStreams.switch()
      (vals...) =>
        _zipObject _keys(@reviewFeaturesFields), vals
    )

    @resetValueStreams()

    @$steps = _filter [
      new @NewPlaceInitialInfo {
        @model, @router, fields: @initialInfoFields, @season
      }
      new @NewReviewExtras {
        @model, @router, fields: @reviewExtraFields,
        fieldsValues: reviewExtraFieldsValues, @season
      }
      if @NewReviewFeatures
        new @NewReviewFeatures {
          @model, @router, fields: @reviewFeaturesFields,
          fieldsValues: reviewFeaturesFieldsValues
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
      nameValue: @initialInfoFields.name.valueStreams.switch()
      detailsValue: @initialInfoFields.details.valueStreams.switch()
      websiteValue: @initialInfoFields.website.valueStreams.switch()
      locationValue: @initialInfoFields.location.valueStreams.switch()
      subTypeValue: @initialInfoFields.subType?.valueStreams.switch()
      agencyValue: @initialInfoFields.agency?.valueStreams.switch()
      regionValue: @initialInfoFields.region?.valueStreams.switch()
      officeValue: @initialInfoFields.office?.valueStreams.switch()
      titleValue: @reviewFields.title.valueStreams.switch()
      bodyValue: @reviewFields.body.valueStreams.switch()
      attachmentsValue: @reviewFields.attachments.valueStreams.switch()
      ratingValue: @reviewFields.rating.valueStreams.switch()
      featuresValue: @reviewFeaturesFields?.features.valueStreams.switch()
      reviewExtraFieldsValues
    }

  upsert: =>
    {me, nameValue, detailsValue, locationValue, subTypeValue, agencyValue,
      regionValue, officeValue, attachmentsValue, websiteValue
      featuresValue} = @state.getValue()

    @state.set isLoading: true

    @model.user.requestLoginIfGuest me
    .then =>
      if _find attachmentsValue, {isUploading: true}
        isReady = confirm @model.l.get 'newReview.pendingUpload'
      else
        isReady = true

      if isReady
        @placeModel.upsert {
          name: nameValue
          details: detailsValue
          location: locationValue
          subType: subTypeValue
          agencySlug: agencyValue
          regionSlug: regionValue
          officeSlug: officeValue
          features: featuresValue
          contact:
            website: websiteValue
        }
        .then @upsertReview
        .catch (err) =>
          err = try
            JSON.parse err.message
          catch
            {}
          console.log err
          @step.next STEPS[err.info.step] or 0
          errorSubject = switch err.info.field
            when 'location' then @initialInfoFields.location.errorSubject
            when 'body' then @reviewFields.body.errorSubject
            else @initialInfoFields.location.errorSubject
          errorSubject.next @model.l.get err.info.langKey
          @state.set isLoading: false
        .then =>
          delete localStorage[LOCAL_STORAGE_AUTOSAVE] # clear autosave
          @state.set isLoading: false
      else
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

  afterMount: =>
    changesStream = @getAllChangesStream()
    @disposable = changesStream.auditTime(AUTOSAVE_FREQ_MS).subscribe (fields) ->
      localStorage[LOCAL_STORAGE_AUTOSAVE] = JSON.stringify fields

  beforeUnmount: =>
    @step.next 0
    @resetValueStreams()
    @disposable.unsubscribe()

  resetValueStreams: =>
    autosave = try
      JSON.parse localStorage[LOCAL_STORAGE_AUTOSAVE]
    catch
      {}

    @initialInfoFields.name.valueStreams.next(
      RxObservable.of autosave['initialInfo.name'] or ''
    )
    @initialInfoFields.details.valueStreams.next(
      RxObservable.of autosave['initialInfo.details'] or ''
    )
    @initialInfoFields.website.valueStreams.next(
      RxObservable.of autosave['initialInfo.websiteUrl'] or ''
    )
    if @initialInfoFields.subType
      @initialInfoFields.subType?.valueStreams.next(
        RxObservable.of autosave['initialInfo.subType'] or 'restArea'
      )
    if @location
      @initialInfoFields.location.valueStreams.next @location.map (location) ->
        location or autosave['initialInfo.location'] or ''

    if @initialInfoFields.agency
      agencyInfo = @initialInfoFields.location.valueStreams.switch().switchMap (location) =>
        if location
          @model.agency.getAgencyInfoFromLocation location
        else
          RxObservable.of null

      @initialInfoFields.subType.valueStreams.next agencyInfo.map (agencyInfo) ->
        if agencyInfo
          'public'
        else
          ''

      @initialInfoFields.agency.valueStreams.next agencyInfo.map (agencyInfo) ->
        agencyInfo?.agencySlug or autosave['initialInfo.agency'] or ''

      @initialInfoFields.region.valueStreams.next agencyInfo.map (agencyInfo) ->
        agencyInfo?.regionSlug or autosave['initialInfo.region'] or ''

      @initialInfoFields.office.valueStreams.next agencyInfo.map (agencyInfo) ->
        agencyInfo?.slug or autosave['initialInfo.office'] or ''




    @reviewFields.title.valueStreams.next(
      RxObservable.of autosave['review.title'] or ''
    )
    @reviewFields.body.valueStreams.next(
      RxObservable.of autosave['review.body'] or ''
    )
    @reviewFields.rating.valueStreams.next(
      RxObservable.of autosave['review.rating'] or null
    )
    @reviewFields.attachments.valueStreams.next new RxBehaviorSubject []
    _forEach @reviewExtraFields, (field, key) ->
      field.valueStreams.next(
        RxObservable.of autosave["reviewExtra.#{key}"] or null
      )

    @$steps?[1].reset()

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

  render: =>
    {step, isLoading, locationValue} = @state.getValue()

    z '.z-new-place',
      z @$appBar, {
        title: @$steps[step].getTitle()
        style: 'primary'
        $topLeftButton: z @$buttonBack
      }

      z '.step', {
        # if DOM el is reused, page stays scrolled down when switching steps
        key: "new-place-#{step}"
      },
        z @$steps[step]

      z @$stepBar, {
        isSaving: false
        steps: @$steps.length
        isStepCompleted: @$steps[step]?.isCompleted?()
        isLoading: isLoading
        save:
          icon: 'arrow-right'
          onclick: =>
            unless isLoading
              @upsert()
      }
