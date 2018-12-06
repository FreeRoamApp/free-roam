z = require 'zorium'

AppBar = require '../../components/app_bar'
ButtonMenu = require '../../components/button_menu'
Settings = require '../../components/settings'
config = require '../../config'

if window?
  require './index.styl'

module.exports = class SettingsPage
  constructor: ({@model, requests, router, serverData, group}) ->
    @$appBar = new AppBar {@model}
    @$buttonMenu = new ButtonMenu {@model, router}
    @$settings = new Settings {@model, router, group}

  getMeta: =>
    {
      title: @model.l.get 'settingsPage.title'
    }

  render: =>
    z '.p-settings',
      z @$appBar, {
        title: @model.l.get 'settingsPage.title'
        style: 'primary'
        $topLeftButton: z @$buttonMenu
      }
      @$settings
