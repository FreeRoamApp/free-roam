z = require 'zorium'

AppBar = require '../../components/app_bar'
ButtonBack = require '../../components/button_back'
Icon = require '../../components/icon'
Trip = require '../../components/trip'
config = require '../../config'
colors = require '../../colors'

if window?
  require './index.styl'

module.exports = class TripPage
  hideDrawer: true

  constructor: ({@model, @router, requests, serverData, group}) ->
    @trip = requests.switchMap ({route}) =>
      if route.params.id
        @model.trip.getById route.params.id
      else
        @model.trip.getByType route.params.type

    @$appBar = new AppBar {@model}
    @$buttonBack = new ButtonBack {@model, @router}
    @$shareIcon = new Icon()
    @$trip = new Trip {@model, @router, @trip}

    @state = z.state {
      @trip
      me: @model.user.getMe()
    }

  getMeta: =>
    @trip.map (trip) =>
      cacheBust = new Date(trip?.lastUpdateTime).getTime()
      {
        title: @getTitle()
        description:  @model.l.get 'tripPage.description'
        openGraph:
          image: @model.image.getSrcByPrefix trip?.imagePrefix, {
            size: 'large', cacheBust
          }
      }

  getTitle: =>
    {me, trip} = @state.getValue()

    isMe = me?.id and me?.id is trip?.userId

    if isMe
      @model.l.get 'tripPage.myTitle', {
        replacements:
          name: trip?.name
      }
    else
      @model.l.get 'tripPage.title', {
        replacements:
          name: @model.user.getDisplayName trip?.user
      }

  render: =>
    z '.p-trip',
      z @$appBar, {
        title: @getTitle()
        isPrimary: true
        $topLeftButton: z @$buttonBack, {color: colors.$primary500Text}
        $topRightButton:
          z '.p-trip_top-right',
            z @$shareIcon,
              icon: 'share'
              color: colors.$primary500Text
              onclick: =>
                @$trip.share()
      }
      @$trip
