z = require 'zorium'

AppBar = require '../../components/app_bar'
ButtonMenu = require '../../components/button_menu'
MyPlaces = require '../../components/my_places'
colors = require '../../colors'
config = require '../../config'

if window?
  require './index.styl'

module.exports = class MyPlacesPage
  # hideDrawer: true

  constructor: ({@model, @router, requests, serverData, group}) ->
    @$appBar = new AppBar {@model}
    @$buttonMenu = new ButtonMenu {@model, @router}
    @$myPlaces = new MyPlaces {@model, @router}

  getMeta: =>
    {
      title: @model.l.get 'myPlacesPage.title'
    }

  render: =>
    z '.p-my-places',
      z @$appBar, {
        title: @model.l.get 'myPlacesPage.title'
        style: 'primary'
        $topLeftButton: z @$buttonMenu, {color: colors.$header500Icon}
      }
      @$myPlaces
