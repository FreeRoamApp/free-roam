z = require 'zorium'
_map = require 'lodash/map'
_find = require 'lodash/find'
RxObservable = require('rxjs/Observable').Observable
require 'rxjs/add/observable/of'

AppBar = require '../../components/app_bar'
ButtonBack = require '../../components/button_back'
Items = require '../../components/items'
Base = require '../base'
colors = require '../../colors'
config = require '../../config'

if window?
  require './index.styl'

module.exports = class ItemsPage extends Base
  hideDrawer: true

  constructor: ({@model, @router, requests, serverData, group}) ->
    filter = @clearOnUnmount requests.map ({route}) =>
      if route.params.category
        {type: 'category', value: route.params.category}
      else if route.params.query
        {type: 'search', value: route.params.query}
      else
        {}

    @$appBar = new AppBar {@model}
    @$buttonBack = new ButtonBack {@model, @router}
    @$items = new Items {@model, @router, filter}

    @state = z.state
      me: @model.user.getMe()
      title: filter.switchMap (filter) =>
        if filter.type is 'category'
          @model.category.getAll()
          .map (categories) ->
            _find(categories, {id: filter.value})?.name
        else
          RxObservable.of filter.value
      windowSize: @model.window.getSize()

  getMeta: ->
    {
      title: "The best products for your RV"
    }

  render: =>
    {me, windowSize, title} = @state.getValue()

    z '.p-items', {
      style:
        height: "#{windowSize.height}px"
    },
      z @$appBar, {
        title: title
        style: 'primary'
        $topLeftButton: z @$buttonBack, {color: colors.$header500Icon}
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
      @$items
