z = require 'zorium'
_map = require 'lodash/map'

AppBar = require '../../components/app_bar'
ButtonMenu = require '../../components/button_menu'
Guides = require '../../components/guides'
colors = require '../../colors'
config = require '../../config'

if window?
  require './index.styl'

module.exports = class GuidesPage
  # hideDrawer: true
  @hasBottomBar: true

  constructor: ({@model, @router, requests, serverData, group, @$bottomBar}) ->
    @$appBar = new AppBar {@model}
    @$buttonMenu = new ButtonMenu {@model, @router}
    @$guides = new Guides {@model, @router}

  getMeta: =>
    {
      title: @model.l.get 'guidesPage.title'
      description: @model.l.get 'guidesPage.description'
    }

  render: =>
    z '.p-guides',
      z @$appBar, {
        title: @model.l.get 'guidesPage.title'
        style: 'primary'
        $topLeftButton: z @$buttonMenu, {color: colors.$header500Icon}
      }
      @$guides
      @$bottomBar
