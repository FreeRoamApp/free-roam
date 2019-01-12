z = require 'zorium'
_map = require 'lodash/map'

AppBar = require '../../components/app_bar'
ButtonMenu = require '../../components/button_menu'
Trips = require '../../components/trips'
colors = require '../../colors'
config = require '../../config'

if window?
  require './index.styl'

module.exports = class TripsPage
  # hideDrawer: true
  @hasBottomBar: true

  constructor: ({@model, @router, requests, serverData, group, @$bottomBar}) ->
    @$appBar = new AppBar {@model}
    @$buttonMenu = new ButtonMenu {@model, @router}
    @$trips = new Trips {@model, @router}

  getMeta: =>
    {
      title: @model.l.get 'tripsPage.title'
      description: @model.l.get 'tripsPage.description'
    }

  render: =>
    z '.p-trips',
      z @$appBar, {
        title: @model.l.get 'tripsPage.title'
        style: 'primary'
        $topLeftButton: z @$buttonMenu, {color: colors.$header500Icon}
      }
      @$trips
      @$bottomBar
