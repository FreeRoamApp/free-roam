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
Comment = require '../comment'
ConversationInput = require '../conversation_input'
Spinner = require '../spinner'
FormattedText = require '../formatted_text'
VoteButton = require '../vote_button'
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
  hideDrawer: true

  constructor: ({@model, @router, thread, @isInline, group}) ->
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
    @$threadUpvoteButton = new VoteButton {@model}
    @$threadDownvoteButton = new VoteButton {@model}

    @$fab = new Fab()
    @$avatar = new Avatar()
    @$author = new Author {@model, @router}

    filter = new RxBehaviorSubject {
      sort: 'popular'
    }
    @filterAndThread = RxObservable.combineLatest(
      filter, thread, (vals...) -> vals
    ).publishReplay(1).refCount()
    @$filterCommentsDialog = new FilterCommentsDialog {
      @model, filter
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
      @isPostLoading
      onPost: @postMessage
      group: group
      onResize: -> null
    }

    @state = z.state
      me: @model.user.getMe()
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
      comments: commentsAndThread.map ([comments, thread]) =>
        if comments?.length is 1 and comments[0] is null
          return null
        comments = _filter comments
        _map comments, (comment) =>
          # cache, otherwise there's a flicker on invalidate
          cacheId = "comment-#{comment.id}"
          $el = @getCached$ cacheId, Comment, {
            @model, @router, comment, @commentStreams, group
          }
          # update cached version
          $el.setComment comment
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
        @model.comment.getAllByTopId thread.id, {
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

    @model.user.requestLoginIfGuest me
    .then =>
      @model.comment.create {
        body: messageBody
        topId: thread.id
        topType: 'thread'
        parentId: thread.id
        parentType: 'thread'
      }
      .then (response) =>
        @isPostLoading.next false
        response
      .catch =>
        @isPostLoading.next false

  render: =>
    {me, thread, $body, comments, windowSize,
      isLoading, group, isPostLoading} = @state.getValue()

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
                    @model.overlay.open new ProfileDialog {
                      @model, @router, user: thread?.user
                    }
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
                  @model.overlay.open @$filterCommentsDialog


        z '.comments-wrapper',

          z '.g-grid',
            z '.reply',
              @$conversationInput
            if not comments
              @$spinner
            else if comments and _isEmpty comments
              z '.no-comments', @model.l.get 'thread.noComments'
            else if comments
              z '.comments',
                [
                  _map comments, ($comment) ->
                    [
                      z $comment
                      z '.divider'
                    ]
                  if isLoading
                    z '.loading', @$spinner
                ]
