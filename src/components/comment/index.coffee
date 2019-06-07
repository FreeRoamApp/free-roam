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
ProfileDialog = require '../profile_dialog'
VoteButton = require '../vote_button'
colors = require '../../colors'
config = require '../../config'

if window?
  require './index.styl'

TITLE_LENGTH = 30
MAX_COMMENT_DEPTH = 3

module.exports = class Comment
  constructor: (options) ->
    {@comment, @depth, @isMe, @model, @router, @commentStreams,
      @group} = options

    @depth ?= 0

    @$message = new Message {
      message: {
        user: @comment.user
        time: @comment.time
        groupUser: @comment.groupUser
        card: @comment.card
        id: @comment.id
      }
      $body: new FormattedText {
        text: @comment.body
        isFullWidth: true
        useThumbnails: true
        @model, @router
      }
      messageBatchesStreams: @commentStreams
      @group, @isMe, @model, @router
    }

    @$upvoteButton = new VoteButton {@model}
    @$downvoteButton = new VoteButton {@model}
    @$replyIcon = new Icon()

    @reply = new RxBehaviorSubject null
    @isPostLoading = new RxBehaviorSubject null

    @$children = _map @comment.children, (childComment) =>
      new Comment {
        comment: childComment
        depth: @depth + 1
        @isMe
        @model
        @router
        @group
      }

    @state = z.state
      me: @model.user.getMe()
      depth: @depth
      comment: @comment
      $children: @$children
      isMe: @isMe
      isReplyVisible: false
      isPostLoading: @isPostLoading
      group: @group
      windowSize: @model.window.getSize()

  # for cached components
  setComment: (comment) =>
    @state.set comment: comment
    isChildUpdated = _map comment.children, (child, i) =>
      if child.body isnt @comment?.children[i]?.body
        @$children[i] ?= new Comment {
          comment: child
          depth: @depth + 1
          @isMe
          @model
          @router
          @group
        }
        @$children[i].setComment child

    if comment.body isnt @comment.body
      @comment = comment


  postReply: =>
    {me, isPostLoading, comment} = @state.getValue()

    if isPostLoading
      return

    body = @reply.getValue()
    @isPostLoading.next true

    @model.user.requestLoginIfGuest me
    .then =>
      @model.comment.create {
        body: body
        topId: comment.topId
        parentId: comment.id
        parentType: 'comment'
        topType: 'thread' # FIXME
      }
      .then (response) =>
        @isPostLoading.next false
        @state.set isReplyVisible: false
        response
      .catch =>
        @isPostLoading.next false

  render: =>
    {depth, isMe, comment, isReplyVisible, group,
      windowSize, $children} = @state.getValue()

    {user, time, card, body, id, clientId} = comment

    hasVotedUp = comment?.myVote?.vote is 1
    hasVotedDown = comment?.myVote?.vote is -1

    # pass these when voting so we can update scylla properly (no index on id)
    voteParent = _pick comment, [
      'id', 'topId', 'userId', 'parentId', 'parentType',
      'timeBucket'
    ]
    voteParent.topId = comment.topId
    voteParent.type = 'comment'

    z '.z-comment', {
      # re-use elements in v-dom
      key: "comment-#{clientId or id}"
      className: z.classKebab {isMe}
    },
      z '.comment',
        z @$message, {
          isTimeAlignedLeft: true
          openProfileDialogFn: (id, user, groupUser) =>
            @model.overlay.open new ProfileDialog {
              @model, @router, user, groupUser
              onDeleteMessage: =>
                @model.comment.deleteByComment voteParent, {
                  groupId: group?.id
                }
                .then =>
                  @commentStreams.take(1).toPromise()
              onDeleteMessagesLast7d: =>
                @model.comment.deleteAllByGroupIdAndUserId(
                  groupUser.groupId, user.id, {
                    duration: '7d', topId: comment.topId
                  }
                )
                .then =>
                  @commentStreams.take(1).toPromise()
            }
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
                    @isPostLoading
                    onPost: @postReply
                    group: @group
                    onResize: -> null
                  }
                  @state.set isReplyVisible: true
            },
              @model.l.get 'general.reply'
              # z @$replyIcon,
              #   icon: 'reply'
              #   isTouchTarget: false
              #   color: colors.$bgText
          z '.points',
            z '.icon',
              z @$upvoteButton, {
                vote: 'up'
                hasVoted: hasVotedUp
                parent: voteParent
                isTouchTarget: false
                color: colors.$bgText54
                size: '14px'
              }

            comment.upvotes or 0

            z '.icon',
              z @$downvoteButton, {
                vote: 'down'
                hasVoted: hasVotedDown
                parent: voteParent
                isTouchTarget: false
                color: colors.$bgText54
                size: '14px'
              }

      z '.reply',
        if isReplyVisible
          @$conversationInput

      z '.children',
        @$children
