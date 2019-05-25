z = require 'zorium'

AppBar = require '../../components/app_bar'
ButtonBack = require '../../components/button_back'
FlatButton = require '../../components/flat_button'
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
    @$viewButton = new FlatButton()
    @$shareButton = new FlatButton()
    @$trip = new Trip {@model, @router, @trip}

    @state = z.state {@trip}

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
        title: @model.l.get 'tripPage.title', {
          replacements:
            name: trip?.name or ''
        }
        isPrimary: true
        $topLeftButton: z @$buttonBack, {color: colors.$primary500Text}
        $topRightButton:
          z '.p-trip_top-right',
            z @$shareButton,
              text: @model.l.get 'general.share'
              colors:
                cText: colors.$primary500Text
              onclick: =>
                @$trip.share()
      }
      @$trip
