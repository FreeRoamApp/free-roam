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
      {
        title: trip?.name
        description: trip?.description
        openGraph:
          image: @model.image.getSrcByPrefix trip?.imagePrefix, 'large'
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
