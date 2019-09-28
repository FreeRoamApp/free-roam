z = require 'zorium'
RxBehaviorSubject = require('rxjs/BehaviorSubject').BehaviorSubject

AppBar = require '../../components/app_bar'
ButtonMenu = require '../../components/button_menu'
TripsMine = require '../../components/trips_mine'
TripsFollowing = require '../../components/trips_following'
Tabs = require '../../components/tabs'
colors = require '../../colors'

if window?
  require './index.styl'

module.exports = class TripsPage
  @hasBottomBar: true

  constructor: ({@model, @router, requests, serverData, group, @$bottomBar}) ->
    @selectedIndex = new RxBehaviorSubject 0

    @$appBar = new AppBar {@model}
    @$tabs = new Tabs {@model, @selectedIndex}
    @$buttonMenu = new ButtonMenu {@model, @router}
    @$tripsMine = new TripsMine {@model, @router}
    @$tripsFollowing = new TripsFollowing {@model, @router}

    # @state = z.state {
    # }

  getMeta: =>
    {
      title: @model.l.get 'tripsPage.title'
      # description: ''
    }

  render: =>
    # {} = @state.getValue()

    z '.p-trips',
      z @$appBar, {
        title: @model.l.get 'tripsPage.title'
        isFlat: true
        isPrimary: true
        $topLeftButton: z @$buttonMenu, {color: colors.$primary500Text}
      }
      z @$tabs,
        isBarFixed: false
        isPrimary: true
        tabs: [
          {
            $menuText: @model.l.get 'tripsPage.mine'
            $el: @$tripsMine
          }
          {
            $menuText: @model.l.get 'tripsPage.following'
            $el: z @$tripsFollowing
          }
        ]
      @$trips
      @$bottomBar
