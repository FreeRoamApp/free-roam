z = require 'zorium'
isUuid = require 'isuuid'

GroupManageChannels = require '../../components/group_manage_channels'
AppBar = require '../../components/app_bar'
ButtonBack = require '../../components/button_back'
colors = require '../../colors'

if window?
  require './index.styl'

module.exports = class GroupManageChannelsPage
  isGroup: true
  hideDrawer: true

  constructor: ({@model, requests, @router, serverData, group}) ->
    user = requests.switchMap ({route}) =>
      @model.user.getById route.params.userId

    @$appBar = new AppBar {@model}
    @$buttonBack = new ButtonBack {@model, @router}
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
        $topLeftButton: z @$buttonBack, {color: colors.$header500Icon}
      }
      @$groupManageChannels
