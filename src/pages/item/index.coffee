z = require 'zorium'

AppBar = require '../../components/app_bar'
ButtondBack = require '../../components/button_back'
Item = require '../../components/item'
BasePage = require '../base'
colors = require '../../colors'
config = require '../../config'

if window?
  require './index.styl'

module.exports = class ItemPage extends BasePage
  hideDrawer: true

  constructor: ({@model, @router, requests, serverData, group}) ->
    @item = @clearOnUnmount requests.switchMap ({route}) =>
      @model.item.getBySlug route.params.slug

    @$appBar = new AppBar {@model}
    @$buttondBack = new ButtondBack {@model, @router}
    @$item = new Item {@model, @router, @item}

    @state = z.state
      me: @model.user.getMe()
      item: @item
      windowSize: @model.window.getSize()

  getMeta: ->
    @item.map (item) ->
      {
        title: "Boondocking #{item?.name}"
      }

  # beforeUnmount: =>
  #   @item.next

  render: =>
    {me, item, windowSize} = @state.getValue()

    z '.p-item', {
      style:
        height: "#{windowSize.height}px"
    },
      z @$appBar, {
        title: item?.name
        style: 'primary'
        $topLeftButton: z @$buttondBack, {color: colors.$header500Icon}
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
      @$item
