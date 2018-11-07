z = require 'zorium'

AppBar = require '../../components/app_bar'
ButtonMenu = require '../../components/button_menu'
Places = require '../../components/places'
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
    @$places = new Places {@model, @router}

  getMeta: =>
    {
      title: @model.l.get 'general.places'
      description: @model.l.get 'meta.defaultDescription'
    }

  render: =>
    z '.p-places',
      z @$appBar, {
        title: @model.l.get 'general.places'
        style: 'primary'
        $topLeftButton: z @$buttonMenu, {color: colors.$header500Icon}
      }
      @$places
      @$bottomBar
