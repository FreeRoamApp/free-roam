z = require 'zorium'
_map = require 'lodash/map'

AppBar = require '../../components/app_bar'
ButtonMenu = require '../../components/button_menu'
Map = require '../../components/map'
colors = require '../../colors'
config = require '../../config'

if window?
  require './index.styl'

module.exports = class PlacesPage
  # hideDrawer: true
  @hasBottomBar: true

  constructor: ({@model, @router, requests, serverData, group, @$bottomBar}) ->
    @$appBar = new AppBar {@model}
    @$buttonMenu = new ButtonMenu {@model, @router}
    @$map = new Map {@model, @router}

    @state = z.state
      me: @model.user.getMe()
      windowSize: @model.window.getSize()

  getMeta: ->
    {
      title: @model.l.get 'places'
    }

  render: =>
    {me, windowSize} = @state.getValue()

    z '.p-places', {
      style:
        height: "#{windowSize.height}px"
    },
      z @$appBar, {
        title: @model.l.get 'general.places'
        style: 'primary'
        $topLeftButton: z @$buttonMenu, {color: colors.$header500Icon}
      }
      @$map
      @$bottomBar
