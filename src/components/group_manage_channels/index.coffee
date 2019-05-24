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
      z '.g-grid',
        z @$channelList, {
          onclick: (e, {id}) =>
            @model.group.goPath group, 'groupAdminEditChannel', {
              @router
              replacements:
                conversationId: id
            }
        }

      z '.fab',
        z @$fab,
          isPrimary: true
          icon: 'add'
          onclick: =>
            @model.group.goPath group, 'groupAdminNewChannel', {@router}
