z = require 'zorium'
isUuid = require 'isuuid'

GroupManageChannels = require '../../components/group_manage_channels'
AppBar = require '../../components/app_bar'
ButtonMenu = require '../../components/button_menu'
colors = require '../../colors'

if window?
  require './index.styl'

module.exports = class GroupManageChannelsPage
  isGroup: true

  constructor: ({@model, requests, @router, serverData, group}) ->
    user = requests.switchMap ({route}) =>
      @model.user.getById route.params.userId

    @$appBar = new AppBar {@model}
    @$buttonMenu = new ButtonMenu {@model, @router}
    @$groupManageChannels = new GroupManageChannels {
      @model, @router, serverData, group, user
    }

  getMeta: =>
    {
      title: @model.l.get 'groupManageChannelsPage.title'
      description: @model.l.get 'groupManageChannelsPage.title'
    }

  render: =>
    z '.p-group-manage-channels',
      z @$appBar, {
        title: @model.l.get 'groupManageChannelsPage.title'
        style: 'primary'
        $topLeftButton: z @$buttonMenu, {color: colors.$header500Icon}
      }
      @$groupManageChannels
