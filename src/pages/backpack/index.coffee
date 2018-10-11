z = require 'zorium'

AppBar = require '../../components/app_bar'
ButtonMenu = require '../../components/button_menu'
Backpack = require '../../components/backpack'
config = require '../../config'
colors = require '../../colors'

if window?
  require './index.styl'

module.exports = class BackpackPage
  constructor: ({@model, @router, requests, serverData, group}) ->
    @$appBar = new AppBar {@model}
    @$buttonMenu = new ButtonMenu {@model, @router}
    @$backpack = new Backpack {@model, @router}

    @state = z.state
      windowSize: @model.window.getSize()

  getMeta: ->
    {
      title: 'Backpack'
    }

  render: =>
    {windowSize} = @state.getValue()

    z '.p-backpack', {
      style:
        height: "#{windowSize.height}px"
    },
      z @$appBar, {
        title: @model.l.get 'drawer.backpack'
        style: 'primary'
        $topLeftButton: z @$buttonMenu, {color: colors.$header500Icon}
        $topRightButton:
          z '.p-group-home_top-right',
            z @$notificationsIcon,
              icon: 'notifications'
              color: colors.$header500Icon
              onclick: =>
                @model.overlay.open @$notificationsOverlay
            z @$settingsIcon,
              icon: 'settings'
              color: colors.$header500Icon
              onclick: =>
                @model.overlay.open.next new SetLanguageDialog {
                  @model, @router, @group
                }
      }
      @$backpack
