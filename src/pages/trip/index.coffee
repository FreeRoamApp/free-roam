z = require 'zorium'

AppBar = require '../../components/app_bar'
ButtonBack = require '../../components/button_back'
Trip = require '../../components/trip'
config = require '../../config'
colors = require '../../colors'

if window?
  require './index.styl'

module.exports = class TripPage
  hideDrawer: true

  constructor: ({@model, @router, requests, serverData, group}) ->
    @trip = requests.switchMap ({route}) =>
      @model.trip.getById route.params.id

    @$appBar = new AppBar {@model}
    @$buttonBack = new ButtonBack {@model, @router}
    @$trip = new Trip {@model, @router, @trip}

    @state = z.state
      trip: @trip

  getMeta: =>
    @trip.map (trip) =>
      cacheBust = new Date(trip?.lastUpdateTime).getTime()
      {
        title: @model.l.get 'tripPage.title'
        description:  @model.l.get 'tripPage.description'
        openGraph:
          image: @model.image.getSrcByPrefix trip?.imagePrefix, {
            size: 'large', cacheBust
          }
      }

  render: =>
    {trip} = @state.getValue()

    z '.p-trip',
      z @$appBar, {
        title: @model.l.get 'tripPage.title'
        style: 'primary'
        $topLeftButton: z @$buttonBack, {color: colors.$header500Icon}
      }
      @$trip
