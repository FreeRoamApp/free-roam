z = require 'zorium'
_defaults = require 'lodash/defaults'
_startCase = require 'lodash/startCase'

Avatar = require '../avatar'
Author = require '../author'
Review = require '../review'
colors = require '../../colors'
config = require '../../config'

if window?
  require './index.styl'

module.exports = class PlaceReview
  constructor: (options) ->
    {@model, @router, @review, parent, @$body, isMe
      @dialogData} = options

    @$avatar = new Avatar()
    @$author = new Author {@model, @router}
    @$review = new Review {
      @model, @router, @review, parent, @$body, isMe
      openDialogFn: @openDialog
    }

    @state = z.state {
      @review
      parent
    }

  openDialog: ({user, review, parent}) =>
    @dialogData.next _defaults user, {
      onDeleteMessage: =>
        @model[review.type].deleteById review.id
      onEditMessage: =>
        @router.go "edit#{_startCase parent.type}Review", {
          slug: parent.slug
          reviewId: review.id
        }
    }

  setReview: =>
    @$review.setReview.apply this, arguments

  render: =>
    {review, parent} = @state.getValue()

    {user, time} = review

    # avatarSize = if windowSize.width > 840 \
    #              then '40px'
    #              else '40px'
    avatarSize = '40px'

    onclick = =>
      @openDialog {user, review, parent}

    z '.z-place-review',
      z '.avatar', {
        onclick
        style:
          width: avatarSize
      },
        z @$avatar, {
          user
          size: avatarSize
          bgColor: colors.$grey200
        }
      z '.content',
        z @$author, {user, time, onclick}
        z @$review
