z = require 'zorium'
supportsWebP = window? and require 'supports-webp'
_map = require 'lodash/map'
_pick = require 'lodash/pick'
_truncate = require 'lodash/truncate'
_defaults = require 'lodash/defaults'
RxBehaviorSubject = require('rxjs/BehaviorSubject').BehaviorSubject

Icon = require '../icon'
Message = require '../message'
ConversationInput = require '../conversation_input'
FormattedText = require '../formatted_text'
ThreadVoteButton = require '../thread_vote_button'
colors = require '../../colors'
config = require '../../config'

if window?
  require './index.styl'

TITLE_LENGTH = 30
MAX_COMMENT_DEPTH = 3

module.exports = class ThreadComment
  constructor: (options) ->
    {@threadComment, @depth, @isMe, @model, @overlay$,
      @selectedProfileDialogUser, @router, @commentStreams,
      @group} = options

    @depth ?= 0

    @$message = new Message {
      message: {
        user: @threadComment.creator
        time: @threadComment.time
        groupUser: @threadComment.groupUser
        card: @threadComment.card
        id: @threadComment.id
      }
      $body: new FormattedText {
        text: @threadComment.body
        isFullWidth: true
        useThumbnails: true
        @model, @router
      }
      messageBatchesStreams: @commentStreams
      @group, @isMe, @model, @overlay$, @selectedProfileDialogUser, @router
    }

    @$upvoteButton = new ThreadVoteButton {@model}
    @$downvoteButton = new ThreadVoteButton {@model}
    @$threadReplyIcon = new Icon()

    @reply = new RxBehaviorSubject null
    @isPostLoading = new RxBehaviorSubject null

    @$children = _map @threadComment.children, (childThreadComment) =>
      new ThreadComment {
        threadComment: childThreadComment
        depth: @depth + 1
        @isMe
        @model
        @overlay$
        @selectedProfileDialogUser
        @router
        @group
      }

    @state = z.state
      me: @model.user.getMe()
      depth: @depth
      threadComment: @threadComment
      $children: @$children
      isMe: @isMe
      isReplyVisible: false
      isPostLoading: @isPostLoading
      group: @group
      windowSize: @model.window.getSize()

  # for cached components
  setThreadComment: (threadComment) =>
    @state.set threadComment: threadComment
    isChildUpdated = _map threadComment.children, (child, i) =>
      if child.body isnt @theadComment?.children[i]?.body
        @$children[i] ?= new ThreadComment {
          threadComment: child
          depth: @depth + 1
          @isMe
          @model
          @overlay$
          @selectedProfileDialogUser
          @router
          @group
        }
        @$children[i].setThreadComment child

    if threadComment.body isnt @threadComment.body
      @threadComment = threadComment
      @state.set
        $body: new FormattedText {
          text: threadComment.body, useThumbnails: true, @model, @router
        }


  postReply: =>
    {me, isPostLoading, threadComment} = @state.getValue()

    if isPostLoading
      return

    body = @reply.getValue()
    @isPostLoading.next true

    @model.signInDialog.openIfGuest me
    .then =>
      @model.threadComment.create {
        body: body
        threadId: threadComment.threadId
        parentId: threadComment.id
        parentType: 'threadComment'
      }
      .then (response) =>
        @isPostLoading.next false
        @state.set isReplyVisible: false
        response
      .catch =>
        @isPostLoading.next false

  render: =>
    {depth, isMe, threadComment, isReplyVisible, $body, group,
      windowSize, $children} = @state.getValue()

    {creator, time, card, body, id, clientId} = threadComment

    hasVotedUp = threadComment?.myVote?.vote is 1
    hasVotedDown = threadComment?.myVote?.vote is -1

    # pass these when voting so we can update scylla properly (no index on id)
    voteParent = _pick threadComment, [
      'id', 'threadId', 'userId', 'parentId', 'parentType',
      'timeId', 'timeBucket'
    ]
    voteParent.topId = threadComment.threadId
    voteParent.type = 'threadComment'

    z '.z-thread-comment', {
      # re-use elements in v-dom
      key: "thread-comment-#{clientId or id}"
      className: z.classKebab {isMe}
    },
      z '.comment',
        z @$message, {
          isTimeAlignedLeft: true
          openProfileDialogFn: (id, user, groupUser) =>
            @selectedProfileDialogUser.next _defaults {
              onDeleteMessage: =>
                @model.threadComment.deleteByThreadComment voteParent, {
                  groupId: group?.id
                }
                .then =>
                  @commentStreams.take(1).toPromise()
              onDeleteMessagesLast7d: =>
                @model.threadComment.deleteAllByGroupIdAndUserId(
                  groupUser.groupId, user.id, {
                    duration: '7d', threadId: threadComment.threadId
                  }
                )
                .then =>
                  @commentStreams.take(1).toPromise()
            }, user
        }

      z '.bottom',
        z '.actions',
          if depth < MAX_COMMENT_DEPTH
            z '.reply', {
              onclick: (e) =>
                e?.stopPropagation()
                if isReplyVisible
                  @state.set isReplyVisible: false
                else
                  @$conversationInput = new ConversationInput {
                    @model
                    @router
                    message: @reply
                    @overlay$
                    @isPostLoading
                    onPost: @postReply
                    group: @group
                    onResize: -> null
                  }
                  @state.set isReplyVisible: true
            },
              @model.l.get 'general.reply'
              # z @$threadReplyIcon,
              #   icon: 'reply'
              #   isTouchTarget: false
              #   color: colors.$tertiary900Text
          z '.points',
            z '.icon',
              z @$upvoteButton, {
                vote: 'up'
                hasVoted: hasVotedUp
                parent: voteParent
                isTouchTarget: false
                color: colors.$tertiary900Text54
                size: '14px'
              }

            threadComment.upvotes or 0

            z '.icon',
              z @$downvoteButton, {
                vote: 'down'
                hasVoted: hasVotedDown
                parent: voteParent
                isTouchTarget: false
                color: colors.$tertiary900Text54
                size: '14px'
              }

      z '.reply',
        if isReplyVisible
          @$conversationInput

      z '.children',
        @$children
