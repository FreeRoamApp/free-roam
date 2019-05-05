z = require 'zorium'
isUuid = require 'isuuid'

AppBar = require '../../components/app_bar'
ButtonBack = require '../../components/button_back'
Tabs = require '../../components/tabs'
GroupEditChannel = require '../../components/group_edit_channel'
GroupEditChannelPermissions =
  require '../../components/group_edit_channel_permissions'
colors = require '../../colors'

if window?
  require './index.styl'

module.exports = class GroupEditChannelPage
  isGroup: true
  hideDrawer: true

  constructor: ({@model, requests, @router, serverData, group}) ->
    conversation = requests.switchMap ({route}) =>
      @model.conversation.getById route.params.conversationId

    @$appBar = new AppBar {@model}
    @$buttonBack = new ButtonBack {@model, @router}
    @$groupEditChannel = new GroupEditChannel {
      @model, @router, serverData, group, conversation
    }
    @$groupEditChannelPermissions = new GroupEditChannelPermissions {
      @model, @router, serverData, group, conversation
    }
    @$tabs = new Tabs {@model}

  getMeta: =>
    {
      title: @model.l.get 'groupEditChannelPage.title'
    }

  render: =>

    z '.p-group-edit-channel',
      z @$appBar, {
        title: @model.l.get 'groupEditChannelPage.title'
        style: 'primary'
        isFlat: true
        $topLeftButton: z @$buttonBack, {color: colors.$header500Icon}
      }
      z @$tabs,
        isBarFixed: false
        tabs: [
          {
            $menuText: @model.l.get 'general.info'
            $el: @$groupEditChannel
          }
          {
            $menuText: @model.l.get 'general.permissions'
            $el: z @$groupEditChannelPermissions
          }
        ]
