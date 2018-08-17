z = require 'zorium'
_map = require 'lodash/map'
_find = require 'lodash/find'

Icon = require '../icon'
colors = require '../../colors'

if window?
  require './index.styl'

module.exports = class ChannelList
  constructor: ({@model, @isOpen, conversations, @selectedConversationUuid}) ->
    me = @model.user.getMe()

    @state = z.state
      me: me
      selectedConversationUuid: @selectedConversationUuid
      conversations: conversations.map (conversations) ->
        _map conversations, (channel) ->
          {
            channel
            $statusIcon: new Icon()
          }

  afterMount: =>
    lastConversationUuid = null
    @disposable = @selectedConversationUuid?.subscribe (uuid) =>
      {conversations} = @state.getValue()
      conversation = _find(
        conversations, ({channel}) -> channel?.uuid is uuid
      )?.channel
      if conversation?.uuid isnt lastConversationUuid
        lastConversationUuid = conversation?.uuid
        if conversation?.notificationCount
          @model.conversation.markReadByUuidAndGroupUuid(
            conversation.uuid, conversation.groupUuid
          )

  beforeUnmount: =>
    @disposable?.unsubscribe?()

  render: ({onclick}) =>
    {me, conversations, selectedConversationUuid} = @state.getValue()

    z '.z-channel-list',
      _map conversations, ({channel}) ->
        isSelected = selectedConversationUuid is channel.uuid
        z '.channel', {
          className: z.classKebab {isSelected}
          onclick: (e) ->
            onclick e, channel
        },
          z '.hashtag', '#'
          z '.info',
            z '.name',
              channel.data?.name
              if channel.notificationCount
                z '.notifications',
                  channel.notificationCount
            z '.description', channel.data?.description
