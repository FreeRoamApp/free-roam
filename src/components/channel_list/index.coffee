z = require 'zorium'
_map = require 'lodash/map'
_find = require 'lodash/find'
_orderBy = require 'lodash/orderBy'

Icon = require '../icon'
colors = require '../../colors'

if window?
  require './index.styl'

module.exports = class ChannelList
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

  onDragOver: (e) =>
    if isBefore(@$$dragEl, e.target)
      e.target.parentNode.insertBefore @$$dragEl, e.target
    else
      e.target.parentNode.insertBefore @$$dragEl, e.target.nextSibling

  onDragEnd: =>
    @$$dragEl = null
    order = _map @$$el.querySelectorAll('.channel'), ({dataset}) ->
      dataset.id
    @onReorder order

  onDragStart: (e) =>
    e.dataTransfer.effectAllowed = 'move'
    e.dataTransfer.setData 'text/plain', null
    @$$dragEl = e.target

  isBefore = (el1, el2) ->
    if el2.parentNode == el1.parentNode
      cur = el1.previousSibling
      while cur
        if cur == el2
          return true
        cur = cur.previousSibling
    false

  render: ({onclick}) =>
    {me, conversations, selectedConversationId} = @state.getValue()

    z '.z-channel-list',
      _map conversations, ({channel}) =>
        isSelected = selectedConversationId is channel.id
        z '.channel', {
          className: z.classKebab {isSelected}
          attributes:
            if @onReorder then {draggable: 'true'} else {}
          dataset:
            if @onReorder then {id: channel.id} else {}
          ondragover: if @onReorder then @onDragOver
          ondragstart: if @onReorder then @onDragStart
          ondragend: if @onReorder then @onDragEnd
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
