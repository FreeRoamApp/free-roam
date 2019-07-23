z = require 'zorium'
isUuid = require 'isuuid'

GroupInfo = require '../../components/group_info'
AppBar = require '../../components/app_bar'
ButtonMenu = require '../../components/button_menu'
colors = require '../../colors'

if window?
  require './index.styl'

module.exports = class GroupInfoPage
  isGroup: true

  constructor: ({@model, requests, @router, serverData, group}) ->
    @$appBar = new AppBar {@model}
    @$buttonMenu = new ButtonMenu {@model, @router}
    @$groupInfo = new GroupInfo {
      @model, @router, group
    }

  getMeta: =>
    {
      title: @model.l.get 'groupInfoPage.title'
    }

  render: =>
    z '.p-group-info',
      z @$appBar, {
        title: @model.l.get 'groupInfoPage.title'
        $topLeftButton: z @$buttonMenu, {
          color: colors.$header500Icon
        }
      }
      @$groupInfo
