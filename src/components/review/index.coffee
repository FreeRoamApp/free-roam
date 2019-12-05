z = require 'zorium'
_map = require 'lodash/map'
_find = require 'lodash/find'
_isEmpty = require 'lodash/isEmpty'
RxObservable = require('rxjs/Observable').Observable
require 'rxjs/add/observable/of'

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
    {@review, parent, @$body, isMe, @model, @router, @openDialogFn} = options

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
    #       @dialogData
    #       @router
    #     }
    #     @$children[i].setReview child

    if review.body isnt @review.body
      @review = review

  render: =>
    {isMe, review, parent, windowSize} = @state.getValue()

    {title, user, attachments, time} = review

    hasVotedUp = review?.myVote?.vote is 1
    hasVotedDown = review?.myVote?.vote is -1

    parent ?= review?.parent

    z '.z-review', {
      # re-use elements in v-dom. doesn't seem to work with prepending more
      className: z.classKebab {isMe}
    },
      z '.rating',
        z @$rating, {size: '18px', color: colors.$secondaryMain}
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
