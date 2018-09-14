z = require 'zorium'

ChannelList = require '../channel_list'
Icon = require '../icon'
Fab = require '../fab'
colors = require '../../colors'

if window?
  require './index.styl'

module.exports = class GroupManageChannels
  constructor: ({@model, @router, group}) ->

    @$fab = new Fab()
    @$addIcon = new Icon()
    @$channelList = new ChannelList {
      @model
      conversations: group.switchMap (group) =>
        @model.group.getAllConversationsById group.id
      onReorder: (order) =>
        {group} = @state.getValue()
        @model.conversation.setOrderByGroupId group.id, order
    }

    @state = z.state {
      group
      me: @model.user.getMe()
    }

  render: =>
    {me, group} = @state.getValue()

    z '.z-group-manage-channels',
      z @$channelList, {
        onclick: (e, {id}) =>
          @model.group.goPath group, 'groupEditChannel', {
            @router
            replacements:
              conversationId: id
          }
      }

      z '.fab',
        z @$fab,
          colors:
            c500: colors.$primary500
          $icon: z @$addIcon, {
            icon: 'add'
            isTouchTarget: false
            color: colors.$primary500Text
          }
          onclick: =>
            @model.group.goPath group, 'groupNewChannel', {@router}
