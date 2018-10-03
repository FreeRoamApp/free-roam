z = require 'zorium'
RxBehaviorSubject = require('rxjs/BehaviorSubject').BehaviorSubject
RxReplaySubject = require('rxjs/ReplaySubject').ReplaySubject
require 'rxjs/add/observable/of'
require 'rxjs/add/observable/combineLatest'
require 'rxjs/add/operator/switch'
require 'rxjs/add/operator/switchMap'
require 'rxjs/add/operator/map'
_defaults = require 'lodash/defaults'
_find = require 'lodash/find'
_filter = require 'lodash/filter'
_mapValues = require 'lodash/mapValues'

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


module.exports = class NewReview
  constructor: ({@model, @router, @overlay$, type, @review, id, parent}) ->
    me = @model.user.getMe()

    type ?= RxObservable.of null

    @season = new RxBehaviorSubject @model.time.getCurrentSeason()

    @reviewFields =
      titleValueStreams: new RxReplaySubject 1
      bodyValueStreams: new RxReplaySubject 1
      ratingValueStreams: new RxReplaySubject 1
      attachmentsValueStreams: new RxReplaySubject 1

    @reviewExtraFields =
      crowds:
        isSeasonal: true
        valueSubject: new RxBehaviorSubject null
        errorSubject: new RxBehaviorSubject null
      fullness:
        isSeasonal: true
        valueSubject: new RxBehaviorSubject null
        errorSubject: new RxBehaviorSubject null
      noise:
        valueSubject: new RxBehaviorSubject null
        errorSubject: new RxBehaviorSubject null
      shade:
        valueSubject: new RxBehaviorSubject null
        errorSubject: new RxBehaviorSubject null
      roadDifficulty:
        valueSubject: new RxBehaviorSubject null
        errorSubject: new RxBehaviorSubject null
      cellSignal:
        valueSubject: new RxBehaviorSubject null
        errorSubject: new RxBehaviorSubject null
      safety:
        valueSubject: new RxBehaviorSubject null
        errorSubject: new RxBehaviorSubject null

    @resetValueStreams()

    @step = new RxBehaviorSubject 0
    @$stepBar = new StepBar {@model, @step}

    @$steps = [
      new NewReviewCompose {
        @model, @router, fields: @reviewFields, @season, @overlay
        uploadFn: (args...) ->
          type.take(1).toPromise().then (type) =>
            @model[type + 'Review'].uploadImage.apply(
              @model[type + 'Review'].uploadImage
              args
            )
      }
      new NewReviewExtras {
        @model, @router, fields: @reviewExtraFields, @season, @overlay$
      }
    ]

    @state = z.state {
      @step
      me: @model.user.getMe()
      titleValue: @reviewFields.titleValueStreams.switch()
      bodyValue: @reviewFields.bodyValueStreams.switch()
      attachmentsValue: @reviewFields.attachmentsValueStreams.switch()
      ratingValue: @reviewFields.ratingValueStreams.switch()
      language: @model.l.getLanguage()
      type: type
      review: @review
      parent: parent
    }

  beforeUnmount: =>
    @resetValueStreams()

  resetValueStreams: =>
    if @review
      @reviewFields.titleValueStreams.next @review.map (review) -> review?.title or ''
      @reviewFields.bodyValueStreams.next @review.map (review) -> review?.body or ''
    else
      @reviewFields.titleValueStreams.next new RxBehaviorSubject ''
      @reviewFields.bodyValueStreams.next new RxBehaviorSubject ''

    @reviewFields.ratingValueStreams.next new RxBehaviorSubject null
    @reviewFields.attachmentsValueStreams.next new RxBehaviorSubject []

  upsert: (e) =>
    {me} = @state.getValue()
    @model.signInDialog.openIfGuest me
    .then =>
      {titleValue, bodyValue, ratingValue, attachmentsValue,
        type, review, language, parent} = @state.getValue()

      if _find attachmentsValue, {isUploading: true}
        isReady = confirm @model.l.get 'newReview.pendingUpload'
      else
        isReady = true

      attachments = _filter attachmentsValue, ({isUploading}) -> not isUploading

      extras = _mapValues @reviewExtraFields, ({valueSubject, isSeasonal}) =>
        value = valueSubject.getValue()
        if isSeasonal and value?
          season = @season.getValue()
          {"#{season}": value}
        else if not isSeasonal
          value

      return console.log 'upsert', {
        id: review?.id
        type: review?.type or type
        parentId: parent?.id
        title: titleValue
        body: bodyValue
        attachments: attachments
        rating: ratingValue
        extras: extras
      }

      if isReady
        @model.campgroundReview.upsert {
          id: review?.id
          type: review?.type or type
          parentId: parent?.id
          title: titleValue
          body: bodyValue
          attachments: attachments
          rating: ratingValue
          extras: extras
        }
        .then (newReview) =>
          @resetValueStreams()
          @router.go 'campgroundWithTab', {
            slug: parent?.slug, tab: 'reviews'
          }, {reset: true}


  render: =>
    {step} = @state.getValue()

    z '.z-new-review',
      z @$steps[step]

      z @$stepBar, {
        isSaving: false
        steps: 2
        isStepCompleted: @$steps[step]?.isCompleted?()
        save:
          icon: 'arrow-right'
          onclick: @upsert
      }
