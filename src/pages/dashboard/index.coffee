z = require 'zorium'

AppBar = require '../../components/app_bar'
ButtonMenu = require '../../components/button_menu'
Dashboard = require '../../components/dashboard'
config = require '../../config'
colors = require '../../colors'

if window?
  require './index.styl'

module.exports = class DashboardPage
  @hasBottomBar: true

  constructor: ({@model, @router, @$bottomBar}) ->
    @$appBar = new AppBar {@model}
    @$buttonMenu = new ButtonMenu {@model, @router}
    @$dashboard = new Dashboard {@model, @router}

  getMeta: =>
    {
      title: @model.l.get 'general.dashboard'
    }

  render: =>
    z '.p-dashboard',
      z @$appBar, {
        title: @model.l.get 'general.dashboard'
        style: 'primary'
        $topLeftButton: z @$buttonMenu, {color: colors.$header500Icon}
      }
      @$dashboard

      @$bottomBar
