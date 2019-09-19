z = require 'zorium'
RxBehaviorSubject = require('rxjs/BehaviorSubject').BehaviorSubject
RxReplaySubject = require('rxjs/ReplaySubject').ReplaySubject
RxObservable = require('rxjs/Observable').Observable
require 'rxjs/add/observable/combineLatest'
_find = require 'lodash/find'
_filter = require 'lodash/filter'
_map = require 'lodash/map'

TravelMap = require '../travel_map'
EditTripNavigateElevation = require '../edit_trip_navigate_elevation'
EditTripNavigateSettings = require '../edit_trip_navigate_settings'
Icon = require '../icon'
Tabs = require '../tabs'
SecondaryButton = require '../secondary_button'
PrimaryButton = require '../primary_button'
GoogleMapsWarningDialog = require '../google_maps_warning_dialog'
DateService = require '../../services/date'
FormatService = require '../../services/format'
MapService = require '../../services/map'
colors = require '../../colors'
config = require '../../config'

if window?
  require './index.styl'

module.exports = class EditTripNavigate
  constructor: ({@model, @router, trip, tripRoute}) ->
    # for changing route
    waypoints = new RxBehaviorSubject []

    avoidHighwaysStreams = new RxReplaySubject 1
    avoidHighwaysStreams.next trip.map (trip) -> trip?.settings?.avoidHighways
    useTruckRouteStreams = new RxReplaySubject 1
    useTruckRouteStreams.next trip.map (trip) -> trip?.settings?.useTruckRoute
    isEditable = new RxBehaviorSubject false

    tripAndTripRoute = RxObservable.combineLatest(
      trip, tripRoute, (vals...) -> vals
    )
    tripAndTripRouteAndWaypointsAndSettings = RxObservable.combineLatest(
      trip, tripRoute, waypoints, avoidHighwaysStreams.switch()
      useTruckRouteStreams.switch(), isEditable, (vals...) -> vals
    )

    routes = tripAndTripRouteAndWaypointsAndSettings.switchMap (obj) =>
      [trip, tripRoute, wp, avoidHighways, useTruckRoute, isEditable] = obj

      @model.trip.getRoutesByIdAndRouteId trip.id, tripRoute.routeId, {
        waypoints: wp
        avoidHighways, useTruckRoute, isEditable
      }

    @$tabs = new Tabs {@model}

    @$editTripNavigateElevation = new EditTripNavigateElevation {
      @model, routes
    }

    @$editTripNavigateSettings = new EditTripNavigateSettings {
      @model, avoidHighwaysStreams, useTruckRouteStreams, isEditable
    }

    @$saveRouteButton = new SecondaryButton()
    @$googleMapsButton = new PrimaryButton()

    mapBoundsStreams = new RxReplaySubject 1
    mapBoundsStreams.next(
      tripRoute.map (tripRoute) =>
        unless tripRoute
          return RxObservable.of {}
        tripRoute.bounds
    )

    destinations = tripAndTripRouteAndWaypointsAndSettings.map (obj) ->
      [trip, tripRoute, wp] = obj
      trip?.destinationsInfo.concat _map wp, (point, i) ->
        {place: {
          name: "#{i}" # index used to remove when tapped again
          location: point
          number: ''
          icon: 'drop_pin'
        }}

    @$travelMap = new TravelMap {
      @model, @router, trip, destinations
      mapBoundsStreams
      onclick: (e) =>
        if e.originalEvent.isPropagationStopped
          return
        e.originalEvent.isPropagationStopped = true
        {isEditable} = @state.getValue()
        if isEditable
          if e.features?[0]
            wp = waypoints.getValue()
            wp.splice wp.length - parseInt(e.features[0].name), 1
            waypoints.next wp
          else
            point = {lat: e.lngLat.lat, lon: e.lngLat.lng}
            waypoints.next waypoints.getValue().concat [point]

      routes: routes.map (routes) ->
        routes = _map routes, ({shape}, i) ->
          {
            geojson: MapService.decodePolyline shape
            color:
              if i is 0
              then colors.getRawColor(colors.$secondary500)
              else colors.getRawColor(colors.$grey500)
          }
        routes.reverse()
    }


    @state = z.state {
      trip
      tripRoute
      isEditable
      waypoints
      avoidHighways: avoidHighwaysStreams.switch()
      useTruckRoute: useTruckRouteStreams.switch()
      start: tripAndTripRoute.map ([trip, tripRoute]) ->
        _find trip.destinationsInfo, {id: tripRoute.startCheckInId}
      end: tripAndTripRoute.map ([trip, tripRoute]) ->
        _find trip.destinationsInfo, {id: tripRoute.endCheckInId}
      routes
    }

  render: =>
    {start, end, isEditable, trip, tripRoute, routes,
      avoidHighways, useTruckRoute, waypoints} = @state.getValue()

    console.log avoidHighways, waypoints

    stops = trip?.stops[tripRoute?.routeId]

    places = _filter [start?.place].concat stops, [end?.place]

    mainRoute = routes?[0]
    altRoute = routes?[1]

    z '.z-edit-trip-navigate', {
      ontouchstart: (e) -> e.stopPropagation()
      onmousedown: (e) -> e.stopPropagation()
    },
      z '.map',
        z @$travelMap
      z '.routes',
        z @$tabs,
          isBarFixed: false
          tabs: [
            {
              $menuText: @model.l.get 'editTripNavigate.info'
              $el: @$editTripNavigateElevation
            }
            {
              $menuText: @model.l.get 'editTripNavigate.editRoute'
              $el: @$editTripNavigateSettings
            }
          ]

        z '.stats',
          z '.main',
            z '.distance-time',
              z '.distance',
                z '.number', FormatService.number mainRoute?.distance
                z '.metric', @model.l.get 'abbr.imperial.mile'
              z '.time',
                DateService.formatSeconds mainRoute?.time, 1
          if altRoute
            z '.alt',
              z '.distance-time',
                z '.distance',
                  z '.number', FormatService.number altRoute?.distance
                  z '.metric', @model.l.get 'abbr.imperial.mile'
                z '.time',
                  DateService.formatSeconds altRoute?.time, 1

        z '.actions',
          z '.actions',
            if isEditable
              z @$saveRouteButton,
                text: @model.l.get 'editTripNavigate.saveRoute'
                onclick: =>
                  @model.trip.setRouteByIdAndRouteId(
                    trip.id, tripRoute.routeId, {
                      isEditable, avoidHighways, useTruckRoute, waypoints
                    }
                  )
            else
              z @$googleMapsButton,
                text: @model.l.get 'editTripNavigate.openGoogleMaps'
                onclick: =>
                  go = =>
                    MapService.getDirectionsBetweenPlaces(
                      places
                      {@model}
                    )
                  if @model.cookie.get('hasSeenGoogleMapsWarning')
                    go()
                  else
                    @model.cookie.set 'hasSeenGoogleMapsWarning', '1'
                    @model.overlay.open new GoogleMapsWarningDialog({@model}), {
                      onComplete: go
                      onCancel: go
                    }
