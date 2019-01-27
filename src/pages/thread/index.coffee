z = require 'zorium'
_find = require 'lodash/find'
RxBehaviorSubject = require('rxjs/BehaviorSubject').BehaviorSubject
RxObservable = require('rxjs/Observable').Observable
require 'rxjs/add/observable/combineLatest'
require 'rxjs/add/operator/switchMap'
require 'rxjs/add/operator/map'

Thread = require '../../components/thread'
Icon = require '../../components/icon'
colors = require '../../colors'

WORDS_IN_DESCRIPTION = 70

if window?
  require './index.styl'

module.exports = class ThreadPage
  hideDrawer: true

  constructor: ({@model, requests, @router, serverData, group}) ->
    # allow reset beforeUnmount so stale thread doesn't show when loading new
    @thread = new RxBehaviorSubject null
    loadedThread = requests.switchMap ({route}) =>
      @model.thread.getBySlug route.params.slug
    thread = RxObservable.merge @thread, loadedThread
    @groupAndThread = RxObservable.combineLatest(
      group, thread, (vals...) -> vals
    )

    @$thread = new Thread {@model, @router, thread, group}

  getMeta: =>
    @groupAndThread.map ([group, thread]) =>
      imageAttachment = _find thread?.attachments, {type: 'image'}
      mediaSrc = @model.image.getSrcByPrefix imageAttachment?.prefix, {
        size: 'large'
      }
      {
        title: thread?.title
        description: thread?.body.replace(/\\n/g, ' ').split(/\s+/)
                    .slice(0, WORDS_IN_DESCRIPTION).join(' ')
        openGraph:
          image: mediaSrc?.split(' ')[0]
        twitter: # TODO: group twitter handle
          siteHandle: '@freeroamapp'
          creatorHandle: '@freeroamapp'
      }

  beforeUnmount: =>
    @thread.next {}

  render: =>
    z '.p-thread',
      z @$thread
