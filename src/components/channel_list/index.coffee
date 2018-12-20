z = require 'zorium'
_map = require 'lodash/map'
_find = require 'lodash/find'
_orderBy = require 'lodash/orderBy'

Base = require '../base'
Icon = require '../icon'
colors = require '../../colors'

if window?
  require './index.styl'

module.exports = class ChannelList extends Base
  constructor: (options) ->
    {@model, @isOpen, conversations, @selectedConversationId,
      @onReorder} = options

    me = @model.user.getMe()

    @state = z.state
      me: me
      selectedConversationId: @selectedConversationId
      conversations: conversations.map (conversations) ->
        conversations = _orderBy conversations, 'rank'
        _map conversations, (channel) ->
          {
            channel
            $statusIcon: new Icon()
          }

  afterMount: (@$$el) =>
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
      _map conversations, ({channel}) =>
        isSelected = selectedConversationId is channel.id
        z '.channel.draggable', {
          className: z.classKebab {isSelected}
          attributes:
            if @onReorder then {draggable: 'true'} else {}
          dataset:
            if @onReorder then {id: channel.id} else {}
          ondragover: if @onReorder then z.ev (e, $$el) => @onDragOver e
          ondragstart: if @onReorder then z.ev (e, $$el) => @onDragStart e
          ondragend: if @onReorder then z.ev (e, $$el) => @onDragEnd e
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
