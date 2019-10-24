z = require 'zorium'
RxBehaviorSubject = require('rxjs/BehaviorSubject').BehaviorSubject
RxReplaySubject = require('rxjs/ReplaySubject').ReplaySubject
RxObservable = require('rxjs/Observable').Observable
require 'rxjs/add/observable/combineLatest'
require 'rxjs/add/observable/of'
_find = require 'lodash/find'
_last = require 'lodash/last'
_map = require 'lodash/map'
_filter = require 'lodash/filter'
_flatten = require 'lodash/flatten'
_defaults = require 'lodash/defaults'
_values = require 'lodash/values'

AppBar = require '../../components/app_bar'
Icon = require '../../components/icon'
EditTripRouteInfo = require '../../components/edit_trip_route_info'
Places = require '../../components/places'
MapService = require '../../services/map'
TripService = require '../../services/trip'
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

    @selectedRoute = new RxBehaviorSubject null
    routeId = RxObservable.combineLatest(
      requests.map ({route}) =>
        route.params.routeId or null

      @selectedRoute
      (routeId, selectedRoute) ->
        selectedRoute or routeId
    )


    tripAndRouteId = RxObservable.combineLatest(
      trip, routeId, (vals...) -> vals
    )
    tripRoute = tripAndRouteId.map ([trip, routeId]) ->
      _find(trip.routes, {routeId}) or null

    tripAndTripRoute = RxObservable.combineLatest(
      trip, tripRoute, (vals...) -> vals
    )

    destinationsStreams = new RxReplaySubject 1
    isEditingRoute = new RxBehaviorSubject false
    @editRouteWaypoints = new RxBehaviorSubject []

    routeFocus = new RxBehaviorSubject null

    routeInfoRoutesStreams = new RxReplaySubject 1
    routes = RxObservable.combineLatest(
      tripAndTripRoute?.map ([trip, tripRoute]) ->
        TripService.getRouteGeoJson trip, tripRoute

      routeInfoRoutesStreams.switch()
      (vals...) ->
        _filter [].concat vals...
    )

    routeInfoDestinationsStreams = new RxReplaySubject 1
    addPlacesStreams = new RxReplaySubject 1
    addPlacesStreams.next RxObservable.combineLatest(
      tripAndTripRoute.switchMap ([trip, tripRoute]) =>
        (if tripRoute?.routeId
          @model.trip.getRouteStopsByTripIdAndRouteIds trip.id, [
            tripRoute.routeId
          ]
        else
          RxObservable.of null
        ).map (stops) ->
          places = _filter _map _flatten(_values(stops)), ({place}, i) ->
            if place
              _defaults {
                hasDot: true
                icon: MapService.getIconByPlace place
              }, place
          places = places.concat _map trip?.destinationsInfo, ({place, id}, i) ->
            isGray = tripRoute and not (id in [
              tripRoute?.startCheckInId, tripRoute?.endCheckInId
            ])
            _defaults {
              # location: place.location # {lat, lon}
              number: i + 1
              checkInId: id
              icon: if isGray \
                    then 'planned_gray'
                    else 'planned'
              selectedIcon: 'planned_selected'
              anchor: 'center'
            }, place
          places

      routeInfoDestinationsStreams.switch()

      routeFocus
      (vals...) ->
        _filter [].concat vals...
    )

    @$editTripRouteInfo = new EditTripRouteInfo {
      @model, @router, trip, tripRoute, tripAndTripRoute, routeFocus
      routesStreams: routeInfoRoutesStreams
      destinationsStreams: routeInfoDestinationsStreams
      isEditingRoute, @selectedRoute
      waypoints: @editRouteWaypoints
    }

    mapBoundsStreams = new RxReplaySubject 1
    # take(1) so it doesn't update any time exoid is cleared
    mapBoundsStreams.next tripAndTripRoute.take(1).map ([trip, tripRoute]) =>
      tripRoute?.bounds or trip.bounds

    @$places = new Places {
      @model, @router, trip, tripRoute, mapBoundsStreams, isEditingRoute,
      @editRouteWaypoints, addPlacesStreams, @selectedRoute
      persistentCookiePrefix: 'trip'
      destinations: destinationsStreams.switch()
      routes: routes
      types: routeId.map (routeId) ->
        if routeId
          ['campground', 'overnight', 'amenity', 'hazard']
        else
          ['campground', 'overnight']
      donut: tripAndRouteId.map ([trip, routeId]) ->
        isVisible = trip?.settings?.donut?.isVisible
        if isVisible and not routeId # don't show for add stop
          {
            location: _last trip.destinations
            min: trip.settings.donut.min
            max: trip.settings.donut.max
          }
    }

    @$appBar = new AppBar {@model}
    @$closeIcon = new Icon()
    @$settingsIcon = new Icon()

    @state = z.state
      trip: trip
      routeId: routeId
      tripRoute: tripRoute

  beforeUnmount: =>
    @selectedRoute.next null
    @editRouteWaypoints.next []

  getMeta: =>
    {
      title: @model.l.get 'editTripAddStopPage.stopTitle'
    }

  render: =>
    {trip, routeId, tripRoute} = @state.getValue()

    z '.p-edit-trip-add-stop',
      z @$appBar, {
        title:
          if routeId
          then @model.l.get 'editTripAddStopPage.stopTitle'
          else @model.l.get 'editTripAddStopPage.destinationTitle'
        isSecondary: true
        $topLeftButton: z @$closeIcon, {
          icon: 'close'
          color: colors.$secondaryMainText
          onclick: =>
            @router.back()
        }
        $topRightButton: z @$settingsIcon, {
          icon: 'settings'
          color: colors.$secondaryMainText
          onclick: =>
            @router.goOverlay 'editTripSettings', {
              id: trip?.id
            }
        }
      }
      @$places
      @$bottomBar
      if tripRoute
        @$editTripRouteInfo
