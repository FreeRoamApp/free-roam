z = require 'zorium'
_defaults = require 'lodash/defaults'
_find = require 'lodash/find'
_filter = require 'lodash/filter'
RxBehaviorSubject = require('rxjs/BehaviorSubject').BehaviorSubject
RxReplaySubject = require('rxjs/ReplaySubject').ReplaySubject
RxObservable = require('rxjs/Observable').Observable
require 'rxjs/add/observable/of'
require 'rxjs/add/observable/combineLatest'
require 'rxjs/add/operator/switch'
require 'rxjs/add/operator/switchMap'
require 'rxjs/add/operator/map'

ComposeReview = require '../compose_review'
Spinner = require '../spinner'
config = require '../../config'

if window?
  require './index.styl'

module.exports = class NewReview
  constructor: ({@model, @router, overlay$, type, @review, id, parent}) ->
    @titleValueStreams ?= new RxReplaySubject 1
    @bodyValueStreams ?= new RxReplaySubject 1
    @ratingValueStreams ?= new RxReplaySubject 0
    @ratingValueStreams.next new RxBehaviorSubject null
    @attachmentsValueStreams ?= new RxReplaySubject 1
    @attachmentsValueStreams.next new RxBehaviorSubject []
    type ?= RxObservable.of null

    @resetValueStreams()

    @$spinner = new Spinner()

    @$composeReview = new ComposeReview {
      @model
      @router
      overlay$
      @titleValueStreams
      @bodyValueStreams
      @ratingValueStreams
      @attachmentsValueStreams
      uploadFn: (args...) ->
        type.take(1).toPromise().then (type) =>
          @model[type + 'Review'].uploadImage.apply(
            @model[type + 'Review'].uploadImage
            args
          )
    }

    @state = z.state
      me: @model.user.getMe()
      titleValue: @titleValueStreams.switch()
      bodyValue: @bodyValueStreams.switch()
      attachmentsValue: @attachmentsValueStreams.switch()
      ratingValue: @ratingValueStreams.switch()
      language: @model.l.getLanguage()
      type: type
      review: @review
      parent: parent

  beforeUnmount: =>
    @resetValueStreams()

  resetValueStreams: =>
    if @review
      @titleValueStreams.next @review.map (review) -> review?.title or ''
      @bodyValueStreams.next @review.map (review) -> review?.body or ''
    else
      @titleValueStreams.next new RxBehaviorSubject ''
      @bodyValueStreams.next new RxBehaviorSubject ''

  submit: (e) =>
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

      if isReady
        @model.campgroundReview.upsert {
          id: review?.id
          type: review?.type or type
          parentId: parent?.id
          title: titleValue
          body: bodyValue
          attachments: attachments
          rating: ratingValue
        }
        .then (newReview) =>
          @resetValueStreams()
          @router.go 'campgroundWithTab', {
            slug: parent?.slug, tab: 'reviews'
          }, {reset: true}

  render: =>

    z '.z-new-review',
      z @$composeReview,
        onDone: @submit
