z = require 'zorium'
_map = require 'lodash/map'
_filter = require 'lodash/filter'
_truncate = require 'lodash/truncate'
_defaults = require 'lodash/defaults'
_find = require 'lodash/find'
_startCase = require 'lodash/startCase'
_isEmpty = require 'lodash/isEmpty'
RxBehaviorSubject = require('rxjs/BehaviorSubject').BehaviorSubject
RxObservable = require('rxjs/Observable').Observable
require 'rxjs/add/observable/of'

Avatar = require '../avatar'
Author = require '../author'
Icon = require '../icon'
AttachmentsList = require '../attachments_list'
Rating = require '../rating'
FormatService = require '../../services/format'
VoteButton = require '../vote_button'
colors = require '../../colors'
config = require '../../config'

if window?
  require './index.styl'

TITLE_LENGTH = 30
DESCRIPTION_LENGTH = 100

module.exports = class Review
  constructor: (options) ->
    {@review, parent, @$body, isGrouped, isMe, @model, @isTextareaFocused
      @selectedProfileDialogUser, @router} = options

    @$avatar = new Avatar()
    @$author = new Author {@model, @router}
    @$rating = new Rating {
      value: RxObservable.of @review?.rating
    }
    @$attachmentsList = new AttachmentsList {
      @model, @router
      attachments:
        RxObservable.of @review?.attachments
    }

    @$upvoteButton = new VoteButton {@model}
    @$downvoteButton = new VoteButton {@model}

    me = @model.user.getMe()

    @state = z.state
      review: @review
      parent: parent
      isMe: isMe
      isGrouped: isGrouped
      isMeMentioned: me.map (me) ->
        mentions = @review?.body?.match? config.MENTION_REGEX
        _find mentions, (mention) ->
          username = mention.replace('@', '').toLowerCase()
          username and username is me?.username
      windowSize: @model.window.getSize()

  # for cached components
  setReview: (review) =>
    @state.set review: review
    # isChildUpdated = _map review.children, (child, i) =>
    #   if child.body isnt @review?.children[i]?.body
    #     @$children[i] ?= new Review {
    #       review: child
    #       depth: @depth + 1
    #       @isMe
    #       @model
    #       @selectedProfileDialogUser
    #       @router
    #       @group
    #     }
    #     @$children[i].setReview child

    if review.body isnt @review.body
      @review = review

  openProfileDialog: ({user, review, parent}) =>
    @selectedProfileDialogUser.next _defaults user, {
      onDeleteMessage: =>
        @model[review.type].deleteById review.id
      onEditMessage: =>
        @router.go "edit#{_startCase review.type}Review", {
          slug: parent.slug
          reviewId: review.id
        }
    }

  render: ({openProfileDialogFn, isTimeAlignedLeft}) =>
    {isMe, review, parent, windowSize} = @state.getValue()

    {title, user, groupUser, attachments, time} = review

    avatarSize = if windowSize.width > 840 \
                 then '40px'
                 else '40px'

    onclick = =>
      unless @isTextareaFocused?.getValue()
        @openProfileDialog {user, review, parent}

    oncontextmenu = =>
      @openProfileDialog {user, review, parent}

    hasVotedUp = review?.myVote?.vote is 1
    hasVotedDown = review?.myVote?.vote is -1

    z '.z-review', {
      # re-use elements in v-dom. doesn't seem to work with prepending more
      className: z.classKebab {isMe}
      oncontextmenu: (e) ->
        e?.preventDefault()
        oncontextmenu?()
    },
      z '.avatar', {
        onclick
        style:
          width: avatarSize
      },
        z @$avatar, {
          user
          groupUser
          size: avatarSize
          bgColor: colors.$grey200
        }

      z '.content',
        z @$author, {user, groupUser, time, isTimeAlignedLeft, onclick}
        z '.rating',
          z @$rating, {size: '16px'}
        z '.title', title
        z '.body',
          @$body
        unless _isEmpty review?.attachments
          z '.attachments',
            @$attachmentsList

        z '.points',
          z '.icon',
            z @$upvoteButton, {
              vote: 'up'
              hasVoted: hasVotedUp
              parent:
                id: review?.id
                type: review?.type
                topId: parent?.id
                topType: parent?.type
              isTouchTarget: false
              color: colors.$bgText54
              size: '14px'
            }

          review.upvotes or 0

          z '.icon',
            z @$downvoteButton, {
              vote: 'down'
              hasVoted: hasVotedDown
              parent:
                id: review?.id
                type: review?.type
                topId: parent?.id
                topType: parent?.type
              isTouchTarget: false
              color: colors.$bgText54
              size: '14px'
            }
