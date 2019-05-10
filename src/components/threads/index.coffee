z = require 'zorium'
_map = require 'lodash/map'
_filter = require 'lodash/filter'
_range = require 'lodash/range'
_find = require 'lodash/find'
_orderBy = require 'lodash/orderBy'
_flatten = require 'lodash/flatten'
_isEmpty = require 'lodash/isEmpty'
_uniqBy = require 'lodash/uniqBy'
_last = require 'lodash/last'
RxReplaySubject = require('rxjs/ReplaySubject').ReplaySubject
RxObservable = require('rxjs/Observable').Observable
require 'rxjs/add/observable/combineLatest'
require 'rxjs/add/observable/of'
require 'rxjs/add/operator/switch'
require 'rxjs/add/operator/map'

Base = require '../base'
ThreadListItem = require '../thread_list_item'
Spinner = require '../spinner'
Environment = require '../../services/environment'
colors = require '../../colors'
config = require '../../config'

if window?
  require './index.styl'

SCROLL_THRESHOLD = 250
SCROLL_THREAD_LOAD_COUNT = 20

module.exports = class Threads extends Base
  constructor: ({@model, @router, @filter, group}) ->
    @$spinner = new Spinner()

    @groupAndFilter = RxObservable.combineLatest(
      group or RxObservable.of null
      @filter
      (vals...) -> vals
    )

    @threadStreams = new RxReplaySubject(1)
    @threadStreamCache = []
    @appendThreadStream @getTopStream()


    @state = z.state
      me: @model.user.getMe()
      language: @model.l.getLanguage()
      filter: @filter
      expandedId: null
      isLoading: false
      chunkedThreads: @threadStreams.switch().map (threads) =>
        # TODO: json file with vars that are used in stylus and js
        # eg $contentMaxWidth
        if window?.matchMedia('(min-width: 1280px)').matches
          cols = 2
        else
          cols = 1

        threads = _map threads, (thread) =>
          $threadListItem = @getCached$ thread.id, ThreadListItem, {
            @model, @router, thread, group
          }
          {
            thread
            $threadListItem
          }
        return _map _range(cols), (colIndex) ->
          _filter threads, (thread, i) -> i % cols is colIndex

  afterMount: (@$$el) =>
    @$$el?.addEventListener 'scroll', @scrollListener
    @$$el?.addEventListener 'resize', @scrollListener

  beforeUnmount: =>
    super()
    @$$el?.removeEventListener 'scroll', @scrollListener
    @$$el?.removeEventListener 'resize', @scrollListener

  scrollListener: =>
    {isLoading} = @state.getValue()

    if isLoading
      return

    $$el = @$$el

    totalScrolled = $$el.scrollTop
    totalScrollHeight = $$el.scrollHeight - $$el.offsetHeight

    if totalScrollHeight - totalScrolled < SCROLL_THRESHOLD
      @loadMore()

  getTopStream: (skip = 0, maxId) =>
    @groupAndFilter.switchMap ([group, filter]) =>
      if group
        @model.thread.getAll {
          groupId: group?.id
          category: filter.filter
          sort: filter.sort
          skip
          maxId
          limit: SCROLL_THREAD_LOAD_COUNT
        }
      else
        RxObservable.of []

  loadMore: =>
    @state.set
      isLoading: true

    {chunkedThreads} = @state.getValue()

    skip = @threadStreamCache.length * SCROLL_THREAD_LOAD_COUNT
    maxId = _last(_last(chunkedThreads))?.thread.id
    threadStream = @getTopStream skip, maxId
    @appendThreadStream threadStream

    threadStream.take(1).toPromise()
    .then =>
      @state.set
        isLoading: false

  appendThreadStream: (threadStream) =>
    @threadStreamCache = @threadStreamCache.concat [threadStream]
    @threadStreams.next \
      RxObservable.combineLatest @threadStreamCache, (threads...) ->
        _flatten threads

  render: =>
    {me, chunkedThreads, language, filter,
      expandedId, isLoading} = @state.getValue()

    # isLite = @model.experiment.get('threads') is 'lite'
    # isControl = not isLite
    isLite = true

    z '.z-threads', {
      className: z.classKebab {isLite}#, isControl}
    }, [
      if chunkedThreads and _isEmpty chunkedThreads[0]
        z '.no-threads',
          @model.l.get 'threads.empty'
      else if chunkedThreads
        z '.g-grid',
          z '.columns',
            _map chunkedThreads, (threads, i) ->
              z '.column',
                _map threads, ({$threadListItem}) ->
                  $threadListItem
          if isLoading
            z '.loading', @$spinner
      else
        @$spinner
    ]
