z = require 'zorium'
_map = require 'lodash/map'
_find = require 'lodash/find'
_defaults = require 'lodash/defaults'
_isEmpty = require 'lodash/isEmpty'
_flatten = require 'lodash/flatten'
_filter = require 'lodash/filter'
Environment = require '../../services/environment'
RxBehaviorSubject = require('rxjs/BehaviorSubject').BehaviorSubject
RxReplaySubject = require('rxjs/ReplaySubject').ReplaySubject
RxObservable = require('rxjs/Observable').Observable
require 'rxjs/add/operator/map'
require 'rxjs/add/operator/switchMap'
require 'rxjs/add/observable/of'
require 'rxjs/add/observable/combineLatest'

colors = require '../../colors'
config = require '../../config'
Base = require '../base'
AppBar = require '../app_bar'
ButtonBack = require '../button_back'
Icon = require '../icon'
Avatar = require '../avatar'
Author = require '../author'
ThreadComment = require '../thread_comment'
ConversationInput = require '../conversation_input'
Spinner = require '../spinner'
FormattedText = require '../formatted_text'
ThreadVoteButton = require '../thread_vote_button'
FilterCommentsDialog = require '../filter_comments_dialog'
Fab = require '../fab'
ProfileDialog = require '../profile_dialog'
FormatService = require '../../services/format'
DateService = require '../../services/date'

if window?
  require './index.styl'

SCROLL_THRESHOLD = 250
SCROLL_COMMENT_LOAD_COUNT = 30
TIME_UNTIL_WIGGLE_MS = 2000

module.exports = class Thread extends Base
  constructor: ({@model, @router, @overlay$, thread, @isInline, group}) ->
    @$appBar = new AppBar {@model}
    @$buttonBack = new ButtonBack {@router}

    @$spinner = new Spinner()
    @$replyIcon = new Icon()
    @$editIcon = new Icon()
    @$pinIcon = new Icon()
    @$shareIcon = new Icon()
    @$deleteIcon = new Icon()
    @$filterIcon = new Icon()
    @$starIcon = new Icon()
    @$threadUpvoteButton = new ThreadVoteButton {@model}
    @$threadDownvoteButton = new ThreadVoteButton {@model}

    @$fab = new Fab()
    @$avatar = new Avatar()
    @$author = new Author {@model, @router}

    @selectedProfileDialogUser = new RxBehaviorSubject false
    @$profileDialog = new ProfileDialog {
      @model, @router, @selectedProfileDialogUser, group
    }

    filter = new RxBehaviorSubject {
      sort: 'popular'
    }
    @filterAndThread = RxObservable.combineLatest(
      filter, thread, (vals...) -> vals
    ).publishReplay(1).refCount()
    @$filterCommentsDialog = new FilterCommentsDialog {
      @model, filter, @overlay$
    }

    @commentStreams = new RxReplaySubject(1)
    @commentStreamCache = []
    @appendCommentStream @getTopStream()

    commentsAndThread = RxObservable.combineLatest(
      @commentStreams.switch()
      thread
      (vals...) -> vals
    )

    @message = new RxBehaviorSubject ''
    @isPostLoading = new RxBehaviorSubject false
    @$conversationInput = new ConversationInput {
      @model
      @router
      @message
      @overlay$
      @isPostLoading
      onPost: @postMessage
      group: group
      onResize: -> null
    }

    @state = z.state
      me: @model.user.getMe()
      selectedProfileDialogUser: @selectedProfileDialogUser
      thread: thread
      hasLoadedAll: false
      group: group
      $body: new FormattedText {
        text: thread.map (thread) ->
          thread?.body
        imageWidth: 'auto'
        isFullWidth: true
        embedVideos: true
        @model
        @router
      }
      isPostLoading: @isPostLoading
      windowSize: @model.window.getSize()
      threadComments: commentsAndThread.map ([threadComments, thread]) =>
        if threadComments?.length is 1 and threadComments[0] is null
          return null
        threadComments = _filter threadComments
        _map threadComments, (threadComment) =>
          # cache, otherwise there's a flicker on invalidate
          cacheId = "threadComment-#{threadComment.id}"
          $el = @getCached$ cacheId, ThreadComment, {
            @model, @router, @selectedProfileDialogUser, threadComment
            @commentStreams, group
          }
          # update cached version
          $el.setThreadComment threadComment
          $el

  afterMount: (@$$el) =>
    @$$content = @$$el?.querySelector '.content'
    @$$content?.addEventListener 'scroll', @scrollListener
    @$$content?.addEventListener 'resize', @scrollListener

    # share wiggle leads to 3.1% more shares vs no wiggle
    @wiggleTimeout = setTimeout =>
      @$$el.querySelector('.share')?.classList.toggle('wiggle')
    , TIME_UNTIL_WIGGLE_MS

  beforeUnmount: =>
    super()
    @$$content?.removeEventListener 'scroll', @scrollListener
    @$$content?.removeEventListener 'resize', @scrollListener
    clearTimeout @wiggleTimeout

  scrollListener: =>
    {isLoading, hasLoadedAll} = @state.getValue()

    if isLoading or not @$$content or hasLoadedAll
      return

    $$el = @$$content

    totalScrolled = $$el.scrollTop
    totalScrollHeight = $$el.scrollHeight - $$el.offsetHeight

    if totalScrollHeight - totalScrolled < SCROLL_THRESHOLD
      @loadMore()

  getTopStream: (skip = 0) =>
    @filterAndThread.switchMap ([filter, thread]) =>
      if thread?.id
        @model.threadComment.getAllByThreadId thread.id, {
          limit: SCROLL_COMMENT_LOAD_COUNT
          skip: skip
          sort: filter?.sort
          groupId: thread.groupId
        }
        .map (comments) ->
          comments or false
      else
        RxObservable.of null

  loadMore: =>
    @state.set isLoading: true

    skip = @commentStreamCache.length * SCROLL_COMMENT_LOAD_COUNT
    commentStream = @getTopStream skip
    @appendCommentStream commentStream

    commentStream.take(1).toPromise()
    .then (comments) =>
      @state.set
        isLoading: false
        hasLoadedAll: _isEmpty comments
    .catch =>
      @state.set
        isLoading: false

  appendCommentStream: (commentStream) =>
    @commentStreamCache = @commentStreamCache.concat [commentStream]
    @commentStreams.next \
      RxObservable.combineLatest @commentStreamCache, (comments...) ->
        _flatten comments

  postMessage: =>
    {me, isPostLoading, thread} = @state.getValue()

    if isPostLoading
      return

    messageBody = @message.getValue()
    @isPostLoading.next true

    @model.signInDialog.openIfGuest me
    .then =>
      @model.threadComment.create {
        body: messageBody
        threadId: thread.id
        parentId: thread.id
        parentType: 'thread'
      }
      .then (response) =>
        @isPostLoading.next false
        response
      .catch =>
        @isPostLoading.next false

  render: =>
    {me, thread, $body, threadComments, windowSize,
      selectedProfileDialogUser, isLoading, group,
      isPostLoading} = @state.getValue()

    hasVotedUp = thread?.myVote?.vote is 1
    hasVotedDown = thread?.myVote?.vote is -1

    hasAdminPermission = @model.thread.hasPermission thread, me, {
      level: 'admin'
    }
    hasPinThreadPermission = @model.groupUser.hasPermission {
      group, meGroupUser: group?.meGroupUser, me
      permissions: ['pinForumThread']
    }
    hasDeleteThreadPermission = @model.groupUser.hasPermission {
      group, meGroupUser: group?.meGroupUser, me
      permissions: ['deleteForumThread']
    }

    points = if thread then thread.upvotes else 0

    isNativeApp = Environment.isNativeApp('freeroam')

    console.log thread

    z '.z-thread',
      z @$appBar, {
        title: ''
        $topLeftButton: if not @isInline \
                        then z @$buttonBack, {
                          color: colors.$header500Icon
                          fallbackPath:
                            @model.group.getPath group, 'groupForum', {
                              @router
                            }
                        }
        $topRightButton:
          z '.z-thread_top-right',
            [
              z '.share', {key: 'share'},
                z @$shareIcon,
                  icon: 'share'
                  color: colors.$header500Icon
                  hasRipple: true
                  onclick: =>
                    ga? 'send', 'event', 'thread', 'share'
                    path = @model.thread.getPath thread, group, @router
                    @model.portal.call 'share.any', {
                      text: thread.title
                      path: path
                      url: "https://#{config.HOST}#{path}"
                    }
              if hasAdminPermission or me?.username is 'austin'
                z @$editIcon,
                  icon: 'edit'
                  color: colors.$header500Icon
                  hasRipple: true
                  onclick: =>
                    @model.group.goPath group, 'groupThreadEdit', {
                      @router
                      replacements:
                        slug: thread.slug
                    }
              if hasPinThreadPermission
                z @$pinIcon,
                  icon: if thread?.isPinned then 'pin-off' else 'pin'
                  color: colors.$header500Icon
                  hasRipple: true
                  onclick: =>
                    if thread?.isPinned
                      @model.thread.unpinById thread.id
                    else
                      @model.thread.pinById thread.id
              if hasDeleteThreadPermission
                z @$deleteIcon,
                  icon: 'delete'
                  color: colors.$header500Icon
                  hasRipple: true
                  onclick: =>
                    if confirm 'Confirm?'
                      @model.thread.deleteById thread.id
                      .then =>
                        @model.group.goPath group, 'groupForum', {@router}
            ]
      }
      z '.content',
        z '.post',
          z '.g-grid',
            z '.top',
              z '.avatar',
                z @$avatar, {user: thread?.user, size: '20px'}
              z '.author',
                z @$author, {
                  user: thread?.user
                  # groupUser: thread?.groupUser
                  time: thread?.time
                  onclick: =>
                    @selectedProfileDialogUser.next thread?.user
                }
            z 'h1.title',
              thread?.title

            z '.body', $body

        z '.divider'
        z '.stats',
          z '.g-grid',
            z '.vote',
              z '.upvote',
                z @$threadUpvoteButton, {
                  vote: 'up'
                  hasVoted: hasVotedUp
                  parent:
                    id: thread?.id
                    type: 'thread'
                }
              z '.downvote',
                z @$threadDownvoteButton, {
                  vote: 'down'
                  hasVoted: hasVotedDown
                  parent:
                    id: thread?.id
                    type: 'thread'
                }
            z '.score',
              "#{FormatService.number points} #{@model.l.get('thread.points')}"
              z 'span', innerHTML: '&nbsp;&middot;&nbsp;'
              "#{FormatService.number thread?.commentCount} "
              @model.l.get 'thread.comments'
            z '.filter-icon',
              z @$filterIcon,
                icon: 'filter'
                isTouchTarget: false
                color: colors.$bgText
                onclick: =>
                  @overlay$.next @$filterCommentsDialog


        z '.comments-wrapper',

          z '.g-grid',
            z '.reply',
              @$conversationInput
            if not threadComments
              @$spinner
            else if threadComments and _isEmpty threadComments
              z '.no-comments', @model.l.get 'thread.noComments'
            else if threadComments
              z '.comments',
                [
                  _map threadComments, ($threadComment) ->
                    [
                      z $threadComment
                      z '.divider'
                    ]
                  if isLoading
                    z '.loading', @$spinner
                ]

      if selectedProfileDialogUser
        z @$profileDialog
