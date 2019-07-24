z = require 'zorium'
_map = require 'lodash/map'
_filter = require 'lodash/filter'
_truncate = require 'lodash/truncate'
_defaults = require 'lodash/defaults'
_find = require 'lodash/find'
RxBehaviorSubject = require('rxjs/BehaviorSubject').BehaviorSubject

Avatar = require '../avatar'
ActionMessage = require '../action_message'
Author = require '../author'
Icon = require '../icon'
FormatService = require '../../services/format'
colors = require '../../colors'
config = require '../../config'

if window?
  require './index.styl'

TITLE_LENGTH = 30
DESCRIPTION_LENGTH = 100

module.exports = class Message
  constructor: (options) ->
    {message, @$body, isGrouped, isMe, @model, @isTextareaFocused
      @router, @group} = options

    @$avatar = new Avatar()
    @$author = new Author {@model, @router}
    @$actionMessage = new ActionMessage {@model, @router, @$body}

    me = @model.user.getMe()

    @state = z.state
      message: message
      isMe: isMe
      isGrouped: isGrouped
      isMeMentioned: me.map (me) ->
        mentions = message?.body?.match? config.MENTION_REGEX
        _find mentions, (mention) ->
          username = mention.replace('@', '').toLowerCase()
          username and username is me?.username
      windowSize: @model.window.getSize()

  render: ({openProfileDialogFn, isTimeAlignedLeft}) =>
    {isMe, message, isGrouped, isMeMentioned, windowSize} = @state.getValue()

    {user, groupUser, time, card, id, clientId} = message

    avatarSize = if windowSize.width > 840 \
                 then '40px'
                 else '40px'

    onclick = =>
      unless @isTextareaFocused?.getValue()
        openProfileDialogFn id, user, groupUser, @group

    oncontextmenu = =>
      openProfileDialogFn id, user, groupUser, @group

    z '.z-message', {
      # re-use elements in v-dom. doesn't seem to work with prepending more
      key: "message-#{id or clientId}"
      className: z.classKebab {isGrouped, isMe, isMeMentioned}
      oncontextmenu: (e) ->
        e?.preventDefault()
        oncontextmenu?()
    },
      z '.avatar', {
        onclick
        style:
          width: avatarSize
      },
        if not isGrouped and message?.type isnt 'action'
          z @$avatar, {
            user
            groupUser
            size: avatarSize
            bgColor: colors.$grey200
          }
        # z '.level', 1

      z '.content',
        if message?.type is 'action'
          z @$actionMessage, {
            user, groupUser, time, isTimeAlignedLeft, onclick
          }
        else if not isGrouped
          z @$author, {user, groupUser, time, isTimeAlignedLeft, onclick}

        unless message?.type is 'action'
          z '.body',
            @$body

        if card?.url
          z '.card', {
            onclick: (e) =>
              e?.stopPropagation()
              @router.openLink card.url
          },
            z '.title', _truncate card.title, {length: TITLE_LENGTH}
            z '.description', _truncate card.description, {
              length: DESCRIPTION_LENGTH
            }
