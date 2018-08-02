z = require 'zorium'
_map = require 'lodash/map'

AppBar = require '../../components/app_bar'
ButtonMenu = require '../../components/button_menu'
Items = require '../../components/items'
colors = require '../../colors'
config = require '../../config'

if window?
  require './index.styl'

module.exports = class ItemsPage
  # hideDrawer: true

  constructor: ({@model, @router, requests, serverData, group}) ->
    @$appBar = new AppBar {@model}
    @$buttonMenu = new ButtonMenu {@model, @router}
    @$items = new Items {@model, @router}

    @state = z.state
      me: @model.user.getMe()
      windowSize: @model.window.getSize()

  getMeta: ->
    {
      title: "How to decide what to buy for your RV"
    }

  afterMount: (@$$el) =>
    @model.additionalScript.add 'css', '/lib/leaflet/leaflet.css'
    @model.additionalScript.add 'js', '/lib/leaflet/leaflet.js'

    setTimeout => # FIXME
      map = L.map(@$$el.querySelector('.map')).setView([
        30.5
        -97.63
      ], 13)
      L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', attribution: '&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors').addTo map
      L.marker([
        30.5
        -97.63
      ]).addTo(map).bindPopup('A pretty CSS3 popup.<br> Easily customizable.').openPopup()
    , 1000


  render: =>
    {me, windowSize} = @state.getValue()

    z '.p-items', {
      style:
        height: "#{windowSize.height}px"
    },
      z @$appBar, {
        title: @model.l.get 'itemsPage.title'
        style: 'primary'
        $topLeftButton: z @$buttonMenu, {color: colors.$header500Icon}
        $topRightButton:
          z '.p-group-home_top-right',
            z @$notificationsIcon,
              icon: 'notifications'
              color: colors.$header500Icon
              onclick: =>
                @overlay$.next @$notificationsOverlay
            z @$settingsIcon,
              icon: 'settings'
              color: colors.$header500Icon
              onclick: =>
                @overlay$.next new SetLanguageDialog {
                  @model, @router, @overlay$, @group
                }
      }
      z '.map',
        style:
          width: '300px'
          height: '300px'
