z = require 'zorium'

colors = require '../../colors'
Icon = require '../icon'
ThreadPreview = require '../thread_preview'
ThreadVoteButton = require '../thread_vote_button'
FormatService = require '../../services/format'
DateService = require '../../services/date'

if window?
  require './index.styl'

module.exports = class ThreadListItem
  constructor: ({@model, @router, thread, group}) ->
    @$threadPreview = new ThreadPreview {@model, thread}
    @$pointsIcon = new Icon()
    @$threadUpvoteButton = new ThreadVoteButton {@model}
    @$threadDownvoteButton = new ThreadVoteButton {@model}
    @$commentsIcon = new Icon()

    @isImageLoaded = @model.image.isLoaded @getImageUrl thread

    @state = z.state
      me: @model.user.getMe()
      language: @model.l.getLanguage()
      group: group
      isExpanded: false
      thread: thread
      hasVotedUp: thread.myVote?.vote is 1
      hasVotedDown: thread.myVote?.vote is -1

  afterMount: (@$$el) =>
    {thread} = @state.getValue()
    unless @isImageLoaded
      @model.image.load @getImageUrl thread
      .then =>
        # don't want to re-render entire state every time a pic loads in
        @$$el?.classList.add 'is-image-loaded'
        @isImageLoaded = true

  getImageUrl: (thread) ->
    mediaAttachment = thread.data?.attachments?[0]
    # FIXME rm after 3/1/2018
    if mediaAttachment?[0]
      mediaAttachment = mediaAttachment[0]

    mediaSrc = mediaAttachment?.previewSrc or mediaAttachment?.src
    mediaSrc = mediaSrc?.split(' ')[0]

  render: ({hasPadding} = {}) =>
    hasPadding ?= true

    {me, language, isExpanded, thread, group,
      hasVotedUp, hasVotedDown} = @state.getValue()

    mediaSrc = @getImageUrl thread
    isPinned = thread.data?.isPinned

    z 'a.z-thread-list-item-new', {
      key: "thread-list-item-#{thread.uuid}"
      href: @model.thread.getPath thread, group, @router
      className: z.classKebab {isExpanded, @isImageLoaded, hasPadding, isPinned}
      onclick: (e) =>
        e.preventDefault()
        # set cache manually so we don't have to re-fetch
        req = {
          body:
            uuid: thread.uuid
            language: language
          path: 'threads.getById'
        }
        @model.exoid.setDataCache req, thread
        @router.goPath @model.thread.getPath(thread, group, @router)
    },
      z '.content',
        z '.info',
          z '.title', thread.data?.title

          if mediaSrc
            z '.image',
              style:
                backgroundImage: "url(#{mediaSrc})"
              onclick: (e) =>
                e?.stopPropagation()
                e?.preventDefault()
                ga? 'send', 'event', 'thread', 'preview', ''
                @state.set isExpanded: not isExpanded

        z '.bottom',
          z '.author',
            z '.name', @model.user.getDisplayName thread.creator
            if thread.creator?.flags?.isStar
              z '.icon',
                z @$starIcon,
                  icon: 'star-tag'
                  color: colors.$tertiary900Text
                  isTouchTarget: false
                  size: '22px'
            z '.middot',
              innerHTML: '&middot;'
            z '.time',
              if thread.time
              then DateService.fromNow thread.time
              else '...'
            z '.comments',
              thread.commentCount or 0
              z '.icon',
                z @$commentsIcon,
                  icon: 'comment'
                  isTouchTarget: false
                  color: colors.$tertiary900Text54
                  size: '14px'

            z '.points',
              z '.icon',
                z @$threadUpvoteButton, {
                  vote: 'up'
                  hasVoted: hasVotedUp
                  parent:
                    uuid: thread.uuid
                    type: 'thread'
                  isTouchTarget: false
                  # ripple uses anchor tag, don't want
                  # anchor within anchor since it breaks
                  # server-side render
                  hasRipple: window?
                  color: colors.$tertiary900Text54
                  size: '14px'
                  onclick: =>
                    @state.set hasVotedUp: true, hasVotedDown: false
                }

              thread.upvotes or 0

              z '.icon',
                z @$threadDownvoteButton, {
                  vote: 'down'
                  hasVoted: hasVotedDown
                  parent:
                    uuid: thread.uuid
                    type: 'thread'
                  isTouchTarget: false
                  # ripple uses anchor tag, don't want
                  # anchor within anchor since it breaks
                  # server-side render
                  hasRipple: window?
                  color: colors.$tertiary900Text54
                  size: '14px'
                  onclick: =>
                    @state.set hasVotedUp: false, hasVotedDown: true
                }
      if isExpanded
        z '.preview',
          z @$threadPreview
