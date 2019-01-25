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
Review = require '../review'
colors = require '../../colors'
config = require '../../config'

if window?
  require './index.styl'

module.exports = class PlaceReview
  constructor: (options) ->
    {@model, @router, @review, user, @$body, isMe
      @dialogData} = options

    @$avatar = new Avatar()
    @$author = new Author {@model, @router}
    @$review = new Review {
      @model, @router, @review, user, @$body, isMe
      openDialogFn: @openDialog
    }

    @state = z.state {
      @review
      user
    }

  openDialog: ({user, review, parent}) =>
    @router.goPlace review?.parent

  setReview: =>
    @$review.setReview.apply this, arguments

  render: =>
    {review, user} = @state.getValue()

    {user, time} = review

    # thumbnailSize = if windowSize.width > 840 \
    #              then '40px'
    #              else '40px'
    thumbnailSize = '40px'
    thumbnail = @model.image.getSrcByPrefix review?.parent?.thumbnailPrefix

    onclick = =>
      @openDialog {user, review, parent}

    z '.z-profile-review',
      z '.thumbnail', {
        onclick
        style:
          width: thumbnailSize
      },
        if thumbnail
          z 'img.img', {
            src: thumbnail, 'tiny'
          }
      z '.content',
        @router.link z 'a.name', {
          href: @router.getPlace review?.parent
        }, review?.parent?.name
        z @$review
