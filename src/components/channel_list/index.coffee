z = require 'zorium'
_map = require 'lodash/map'
_find = require 'lodash/find'

Icon = require '../icon'
colors = require '../../colors'

if window?
  require './index.styl'

module.exports = class ChannelList
  constructor: ({@model, @isOpen, conversations, @selectedConversationId}) ->
    me = @model.user.getMe()

    @state = z.state
      me: me
      selectedConversationId: @selectedConversationId
      conversations: conversations.map (conversations) ->
        _map conversations, (channel) ->
          {
            channel
            $statusIcon: new Icon()
          }

  afterMount: =>
    lastConversationId = null
    @disposable = @selectedConversationId?.subscribe (id) =>
      {conversations} = @state.getValue()
      conversation = _find(
        conversations, ({channel}) -> channel?.id is id
      )?.channel
      if conversation?.id isnt lastConversationId
        lastConversationId = conversation?.id
        if conversation?.notificationCount
          @model.conversation.markReadByIdAndGroupId(
            conversation.id, conversation.groupId
          )

  beforeUnmount: =>
    @disposable?.unsubscribe?()

  render: ({onclick}) =>
    {me, conversations, selectedConversationId} = @state.getValue()

    z '.z-channel-list',
      _map conversations, ({channel}) ->
        isSelected = selectedConversationId is channel.id
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
