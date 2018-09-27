z = require 'zorium'
_map = require 'lodash/map'
_filter = require 'lodash/filter'
_truncate = require 'lodash/truncate'
_defaults = require 'lodash/defaults'
_find = require 'lodash/find'
RxBehaviorSubject = require('rxjs/BehaviorSubject').BehaviorSubject
RxObservable = require('rxjs/Observable').Observable
require 'rxjs/add/observable/of'

Avatar = require '../avatar'
Author = require '../author'
Icon = require '../icon'
ImageViewOverlay = require '../image_view_overlay'
Rating = require '../rating'
FormatService = require '../../services/format'
colors = require '../../colors'
config = require '../../config'

if window?
  require './index.styl'

TITLE_LENGTH = 30
DESCRIPTION_LENGTH = 100

module.exports = class Review
  constructor: (options) ->
    {review, @$body, isGrouped, isMe, @model, @overlay$, @isTextareaFocused
      @selectedProfileDialogUser, @router} = options

    @$avatar = new Avatar()
    @$author = new Author {@model, @router}
    @$rating = new Rating {
      value: RxObservable.of review?.rating
    }

    me = @model.user.getMe()

    @state = z.state
      review: review
      isMe: isMe
      isGrouped: isGrouped
      isMeMentioned: me.map (me) ->
        mentions = review?.body?.match? config.MENTION_REGEX
        _find mentions, (mention) ->
          username = mention.replace('@', '').toLowerCase()
          username and username is me?.username
      windowSize: @model.window.getSize()

  render: ({openProfileDialogFn, isTimeAlignedLeft}) =>
    {isMe, review, windowSize} = @state.getValue()

    {title, user, groupUser, attachments, time} = review

    avatarSize = if windowSize.width > 840 \
                 then '40px'
                 else '40px'

    onclick = =>
      unless @isTextareaFocused?.getValue()
        @selectedProfileDialogUser.next user

    oncontextmenu = =>
      @selectedProfileDialogUser.next user

    isModerator = groupUser?.roleNames and
                  (
                    groupUser.roleNames.indexOf('mod') isnt -1 or
                    groupUser.roleNames.indexOf('mods') isnt -1
                  )

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
        z '.attachments',
          _map attachments, (attachment) =>
            z '.attachment',
              title: attachment.caption
              onclick: =>
                @overlay$?.next new ImageViewOverlay {
                  @model
                  @router
                  @overlay$
                  imageData:
                    url: attachment.largeSrc
                    aspectRatio: attachment.aspectRatio
                }
              style:
                backgroundImage: "url(#{attachment.smallSrc})"
