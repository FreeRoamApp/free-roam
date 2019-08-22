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
  constructor: ({@model, @router, requests, serverData, group}) ->
    @trip = requests.switchMap ({route}) =>
      if route.params.id
        @model.trip.getById route.params.id
      else
        @model.trip.getByType route.params.type

    @$appBar = new AppBar {@model}
    @$buttonBack = new ButtonBack {@model, @router}
    @$shareIcon = new Icon()
    @$editIcon = new Icon()
    @$trip = new Trip {@model, @router, @trip}

    @state = z.state {
      @trip
      me: @model.user.getMe()
    }

  getMeta: =>
    @trip.map (trip) =>
      cacheBust = new Date(trip?.lastUpdateTime).getTime()
      {
        title: @model.l.get 'tripPage.title', {
          replacements:
            name: trip?.name
        }
        description:  @model.l.get 'tripPage.description', {
          replacements:
            name: trip?.name
            username: @model.user.getDisplayName trip?.user
        }
        openGraph:
          image: @model.image.getSrcByPrefix trip?.imagePrefix, {
            size: 'large', cacheBust
          }
      }

  render: =>
    {me, trip} = @state.getValue()

    hasEditPermission = @model.trip.hasEditPermission trip, me

    z '.p-trip',
      z @$appBar, {
        isFlat: true
        $topLeftButton: z @$buttonBack, {color: colors.$header500Icon}
        $topRightButton:
          z '.p-trip_top-right',
            z @$shareIcon,
              icon: 'share'
              color: colors.$header500Icon
              onclick: =>
                @$trip.share()
            if hasEditPermission
              z @$editIcon,
                icon: 'edit'
                color: colors.$header500Icon
                onclick: =>
                  @router.go 'editTrip', {id: trip.id}
      }
      @$trip
