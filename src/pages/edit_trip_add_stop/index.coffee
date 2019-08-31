z = require 'zorium'
RxReplaySubject = require('rxjs/ReplaySubject').ReplaySubject
RxObservable = require('rxjs/Observable').Observable
require 'rxjs/add/observable/combineLatest'
require 'rxjs/add/observable/of'
_find = require 'lodash/find'
_last = require 'lodash/last'

AppBar = require '../../components/app_bar'
Icon = require '../../components/icon'
Places = require '../../components/places'
colors = require '../../colors'
config = require '../../config'

if window?
  require './index.styl'

module.exports = class EditTripAddStopPage
  hideDrawer: true

  constructor: ({@model, @router, requests, serverData, group, @$bottomBar}) ->
    trip = requests.switchMap ({route}) =>
      if route.params.id
        @model.trip.getById route.params.id
      else
        RxObservable.of null

    routeId = requests.map ({route}) =>
      route.params.routeId

    tripAndRouteId = RxObservable.combineLatest(
      trip, routeId, (vals...) -> vals
    )
    tripRoute = tripAndRouteId.map ([trip, routeId]) ->
      _find trip.routes, {id: routeId}

    # mapBoundsStreams = new RxReplaySubject 1
    # mapBoundsStreams.next requests.switchMap ({route}) =>
    #   region = {
    #     country: route.params.country
    #     state: route.params.state
    #     city: route.params.city
    #   }
    #   unless route.params.country
    #     return RxObservable.of undefined
    #   @model.geocoder.getBoundingFromRegion region

    @$appBar = new AppBar {@model}
    @$closeIcon = new Icon()
    @$settingsIcon = new Icon()

    @$places = new Places {
      @model, @router, trip, tripRoute
      donut: trip.map (trip) ->
        isVisible = trip?.settings?.donut?.isVisible
        console.log 'TRIPPPP', trip
        if isVisible
          console.log 'visible'
          {
            location: _last trip.destinations
            min: trip.settings.donut.min
            max: trip.settings.donut.max
          }
    }

    @state = z.state
      trip: trip
      routeId: routeId

  getMeta: =>
    {
      title: @model.l.get 'editTripAddStopPage.stopTitle'
    }

  render: =>
    {trip, routeId} = @state.getValue()

    z '.p-edit-trip-add-stop',
      z @$appBar, {
        title:
          if routeId
          then @model.l.get 'editTripAddStopPage.stopTitle'
          else @model.l.get 'editTripAddStopPage.destinationTitle'
        isSecondary: true
        $topLeftButton: z @$closeIcon, {
          icon: 'close'
          color: colors.$secondary500Text
          onclick: =>
            @router.back()
        }
        $topRightButton: z @$settingsIcon, {
          icon: 'settings'
          color: colors.$secondary500Text
          onclick: =>
            @router.goOverlay 'editTripSettings', {
              id: trip?.id
            }
        }
      }
      @$places
      @$bottomBar
