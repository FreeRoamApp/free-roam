z = require 'zorium'
isUuid = require 'isuuid'

GroupSettings = require '../../components/group_settings'
AppBar = require '../../components/app_bar'
ButtonMenu = require '../../components/button_menu'
colors = require '../../colors'

if window?
  require './index.styl'

module.exports = class GroupSettingsPage
  isGroup: true

  constructor: ({@model, requests, @router, serverData, group}) ->
    @$appBar = new AppBar {@model}
    @$buttonMenu = new ButtonMenu {@model, @router}
    @$groupSettings = new GroupSettings {
      @model, @router, serverData, group
    }

  getMeta: =>
    {
      title: @model.l.get 'groupSettingsPage.title'
    }

  render: =>
    z '.p-group-settings',
      z @$appBar, {
        title: @model.l.get 'groupSettingsPage.title'
        $topLeftButton: z @$buttonMenu, {
          color: colors.$header500Icon
        }
      }
      @$groupSettings
