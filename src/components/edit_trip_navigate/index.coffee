z = require 'zorium'
RxObservable = require('rxjs/Observable').Observable
require 'rxjs/add/observable/combineLatest'
_find = require 'lodash/find'
_filter = require 'lodash/filter'
_map = require 'lodash/map'

ElevationChart = require '../elevation_chart'
TravelMap = require '../travel_map'
Icon = require '../icon'
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
    tripAndTripRoute = RxObservable.combineLatest(
      trip, tripRoute, (vals...) -> vals
    )

    routes = tripAndTripRoute.switchMap ([trip, tripRoute]) =>
      @model.trip.getRoutesByTripIdAndRouteId trip.id, tripRoute.routeId

    @$gainIcon = new Icon()
    @$lostIcon = new Icon()

    @$elevationChart = new ElevationChart {
      @model
      routes
      size: @model.window.getSize().map ({width}) ->
        {width}
    }

    @$googleMapsButton = new PrimaryButton()

    @$travelMap = new TravelMap {
      @model, @router, trip
      routes: routes.map (routes) ->
        _map routes, ({shape}, i) ->
          {
            geojson: MapService.decodePolyline shape
            color:
              if i is 0
              then colors.getRawColor(colors.$secondary500)
              else colors.getRawColor(colors.$grey500)
          }
    }


    @state = z.state {
      trip
      tripRoute
      start: tripAndTripRoute.map ([trip, tripRoute]) ->
        _find trip.destinationsInfo, {id: tripRoute.startCheckInId}
      end: tripAndTripRoute.map ([trip, tripRoute]) ->
        _find trip.destinationsInfo, {id: tripRoute.endCheckInId}
      routes
    }

  render: =>
    {start, end, trip, tripRoute, routes} = @state.getValue()

    console.log 'routes', routes
    stops = trip?.stops[tripRoute?.routeId]

    places = _filter [start?.place].concat stops, [end?.place]

    console.log 'places', places

    mainRoute = routes?[0]

    z '.z-edit-trip-navigate', {
      ontouchstart: (e) -> e.stopPropagation()
      onmousedown: (e) -> e.stopPropagation()
    },
      z @$travelMap
      z '.routes',
        z '.elevation',
          z '.icon',
            z @$gainIcon,
              icon: 'arrow-up'
              isTouchTarget: false
              color: colors.$secondary500
          z '.text',
            "#{mainRoute?.elevationStats.gained} "
            @model.l.get 'abbr.imperial.foot'
          z '.icon',
            z @$lostIcon,
              icon: 'arrow-down'
              isTouchTarget: false
              color: colors.$secondary500
          z '.text',
            "#{mainRoute?.elevationStats.lost} "
            @model.l.get 'abbr.imperial.foot'

        @$elevationChart

        z '.distance-time',
          z '.distance',
            z '.number', FormatService.number mainRoute?.distance
            z '.metric', @model.l.get 'abbr.imperial.mile'
          z '.time',
            DateService.formatSeconds mainRoute?.time, 1

        z '.actions',
          z '.actions',
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
