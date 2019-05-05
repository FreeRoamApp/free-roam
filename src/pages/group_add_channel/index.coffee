z = require 'zorium'
isUuid = require 'isuuid'

AppBar = require '../../components/app_bar'
ButtonBack = require '../../components/button_back'
GroupEditChannel = require '../../components/group_edit_channel'
colors = require '../../colors'

if window?
  require './index.styl'

module.exports = class GroupAddChannelPage
  isGroup: true
  hideDrawer: true

  constructor: ({@model, requests, @router, serverData, group}) ->
    @$appBar = new AppBar {@model}
    @$buttonBack = new ButtonBack {@model, @router}
    @$groupEditChannel = new GroupEditChannel {
      @model, @router, serverData, group
    }

    @state = z.state {
      windowSize: @model.window.getSize()
    }

  getMeta: =>
    {
      title: @model.l.get 'groupAddChannelPage.title'
    }

  render: =>
    {windowSize} = @state.getValue()

    z '.p-group-add-channel', {
      style:
        height: "#{windowSize.height}px"
    },
      z @$appBar, {
        title: @model.l.get 'groupAddChannelPage.title'
        style: 'primary'
        $topLeftButton: z @$buttonBack, {color: colors.$header500Icon}
      }
      z @$groupEditChannel, {isNewChannel: true}
