z = require 'zorium'
_map = require 'lodash/map'

Icon = require '../icon'
ChannelList = require '../channel_list'
Drawer = require '../drawer'
colors = require '../../colors'

if window?
  require './index.styl'

DRAWER_RIGHT_PADDING = 56
DRAWER_MAX_WIDTH = 336

module.exports = class ChannelDrawer
  constructor: ({@model, @router, @isOpen, group, conversation}) ->
    me = @model.user.getMe()

    isStatic = @model.window.getBreakpoint().map (breakpoint) ->
      breakpoint in ['desktop']
    .publishReplay(1).refCount()

    @$channelList = new ChannelList {
      @model
      @router
      selectedConversationId: conversation.map (conversation) ->
        conversation?.id
      conversations: group.switchMap (group) =>
        @model.conversation.getAllByGroupId group.id
    }
    @$drawer = new Drawer {
      @model
      side: 'right'
      key: 'channel'
      @isOpen
      isStatic: isStatic
      onOpen: =>
        @isOpen.next true
      onClose: =>
        @isOpen.next false
    }
    @$manageChannelsSettingsIcon = new Icon()

    @state = z.state
      isOpen: @isOpen
      group: group
      conversation: conversation
      me: @model.user.getMe()

  render: =>
    {isOpen, group, me, conversation, isStatic} = @state.getValue()

    z '.z-channel-drawer', {
      className: z.classKebab {isStatic}
    },
      z @$drawer,
        hasAppBar: true
        $content:
          z '.z-channel-drawer_drawer',
            z '.title', @model.l.get 'channelDrawer.title'

            z @$channelList, {
              onclick: (e, {id}) =>
                @model.group.goPath group, 'groupChatConversation', {
                  @router, replacements: {conversationId: id}
                }, {ignoreHistory: true}
                @isOpen.next false
            }

            # if hasAdminPermission
            #   [
            #     z '.divider'
            #     z '.manage-channels', {
            #       onclick: =>
            #         @model.group.goPath group, 'groupAdminManageChannels', {
            #           @router
            #         }
            #     },
            #       z '.icon',
            #         z @$manageChannelsSettingsIcon,
            #           icon: 'settings'
            #           isTouchTarget: false
            #           color: colors.$primary500
            #       z '.text', 'Manage channels'
            #   ]
