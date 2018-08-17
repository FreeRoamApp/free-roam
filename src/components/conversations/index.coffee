z = require 'zorium'
_map = require 'lodash/map'
_filter = require 'lodash/filter'
_isEmpty = require 'lodash/isEmpty'
_find = require 'lodash/find'
RxObservable = require('rxjs/Observable').Observable
require 'rxjs/add/observable/combineLatest'

Icon = require '../icon'
Avatar = require '../avatar'
Spinner = require '../spinner'
DateService = require '../../services/date'

if window?
  require './index.styl'

IMAGE_REGEX_STR = '\!\\[(.*?)\\]\\((.*?)\\)'
IMAGE_REGEX = new RegExp IMAGE_REGEX_STR, 'gi'

module.exports = class Conversations
  constructor: ({@model, @router}) ->
    @$spinner = new Spinner()
    @$addIcon = new Icon()

    me = @model.user.getMe()

    conversationsAndBlockedUserIdsAndMe = RxObservable.combineLatest(
      @model.conversation.getAll()
      @model.userBlock.getAllIds()
      me
      (vals...) -> vals
    )

    @state = z.state
      me: me
      conversations: conversationsAndBlockedUserIdsAndMe
      .map ([conversations, blockedUserIds, me]) =>
        _filter _map conversations, (conversation) =>
          otherUser = _find conversation.users, (user) ->
            user.id isnt me?.id
          isBlocked = @model.userBlock.isBlocked blockedUserIds, otherUser?.id
          unless isBlocked
            {conversation, otherUser, $avatar: new Avatar()}

  render: =>
    {me, conversations} = @state.getValue()

    z '.z-conversations',
      z '.g-grid',
        if conversations and _isEmpty conversations
          z '.no-conversations',
            @model.l.get 'conversations.noneFound'
        else if conversations
          _map conversations, ({conversation, otherUser, $avatar}) =>
            isUnread = not conversation?.isRead
            isLastMessageFromMe = conversation.lastMessage?.userId is me?.id

            @router.link z 'a.conversation', {
              href: @router.get 'conversation', {id: conversation.id}
              className: z.classKebab {isUnread}
            },
              z '.status'
              z '.avatar', z $avatar, {user: otherUser}
              z '.right',
                z '.info',
                  z '.name', @model.user.getDisplayName otherUser
                  z '.time',
                    DateService.fromNow conversation.lastUpdateTime
                z '.last-message',
                  if isLastMessageFromMe
                    @model.l.get 'conversations.me'
                  else if conversation.lastMessage
                    "#{@model.user.getDisplayName otherUser}: "

                  conversation.lastMessage?.body?.replace IMAGE_REGEX, 'image'

        else
          @$spinner
