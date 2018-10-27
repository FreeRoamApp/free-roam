z = require 'zorium'
_defaults = require 'lodash/defaults'
RxBehaviorSubject = require('rxjs/BehaviorSubject').BehaviorSubject
RxReplaySubject = require('rxjs/ReplaySubject').ReplaySubject
RxObservable = require('rxjs/Observable').Observable
require 'rxjs/add/observable/of'
require 'rxjs/add/observable/combineLatest'
require 'rxjs/add/operator/switch'
require 'rxjs/add/operator/switchMap'
require 'rxjs/add/operator/map'

Compose = require '../compose'
Spinner = require '../spinner'
config = require '../../config'

if window?
  require './index.styl'

module.exports = class NewThread
  constructor: ({@model, @router, category, @thread, id, group}) ->
    @titleValueStreams ?= new RxReplaySubject 1
    @bodyValueStreams ?= new RxReplaySubject 1
    @attachmentsValueStreams ?= new RxReplaySubject 1
    @attachmentsValueStreams.next new RxBehaviorSubject []
    category ?= RxObservable.of null

    @resetValueStreams()

    @$spinner = new Spinner()

    @$compose = new Compose {
      @model
      @router
      @titleValueStreams
      @bodyValueStreams
      @attachmentsValueStreams
      uploadFn: @model.thread.uploadImage
    }

    categoryAndMe = RxObservable.combineLatest(
      category
      @model.user.getMe()
      (vals...) -> vals
    )
    categoryAndId = RxObservable.combineLatest(
      category
      id or RxObservable.of null
      (vals...) -> vals
    )

    @state = z.state
      me: @model.user.getMe()
      titleValue: @titleValueStreams.switch()
      bodyValue: @bodyValueStreams.switch()
      attachmentsValue: @attachmentsValueStreams.switch()
      category: category
      thread: @thread
      group: group

  beforeUnmount: =>
    @resetValueStreams()

  resetValueStreams: =>
    if @thread
      @titleValueStreams.next @thread.map (thread) -> thread?.title or ''
      @bodyValueStreams.next @thread.map (thread) -> thread?.body or ''
    else
      @titleValueStreams.next new RxBehaviorSubject ''
      @bodyValueStreams.next new RxBehaviorSubject ''

  render: =>
    {me, titleValue, bodyValue, attachmentsValue,
      category, thread, group} = @state.getValue()

    z '.z-new-thread',
      z @$compose,
        imagesAllowed: true
        onDone: (e) =>
          @model.user.requestLoginIfGuest me
          .then =>
            newThread = {
              thread:
                id: thread?.id
                category: thread?.category or category
                title: titleValue
                body: bodyValue
                attachments: attachmentsValue
              groupId: group.id
            }
            (if thread
              @model.thread.upsert _defaults({id: thread.id}, newThread)
            else
              @model.thread.upsert newThread)
            .then (newThread) =>
              console.log 'newthread', newThread
              @resetValueStreams()
              # FIXME FIXME: rm HACK. for some reason thread is empty initially?
              # still unsure why
              setTimeout =>
                @router.goPath(
                  @model.thread.getPath(
                    _defaults(newThread, thread), group, @router
                  )
                  {reset: true}
                )
              , 200
