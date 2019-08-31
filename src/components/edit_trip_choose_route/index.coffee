z = require 'zorium'
RxObservable = require('rxjs/Observable').Observable
require 'rxjs/add/observable/combineLatest'
_map = require 'lodash/map'

ElevationChart = require '../elevation_chart'
TravelMap = require '../travel_map'
MapService = require '../../services/map'
colors = require '../../colors'
config = require '../../config'

if window?
  require './index.styl'

module.exports = class EditTripChooseRoute
  constructor: ({@model, @router, trip, tripRoute}) ->
    tripAndTripRoute = RxObservable.combineLatest(
      trip, tripRoute, (vals...) -> vals
    )

    routes = tripAndTripRoute.switchMap ([trip, tripRoute]) =>
      console.log trip, tripRoute
      @model.trip.getRoutesByTripIdAndRouteId trip.id, tripRoute.id

    @$elevationChart = new ElevationChart {
      routes: routes.map (routes) -> routes
      size: @model.window.getSize().map ({width}) ->
        {width}
    }

    @$travelMap = new TravelMap {
      @model, @router, trip
      routes: routes.map (routes) ->
        _map routes, (route, i) ->
          {
            geojson: MapService.decodePolyline route.legs[0].shape
            color:
              if i is 0
              then colors.getRawColor(colors.$secondary500)
              else colors.getRawColor(colors.$grey500)
          }
    }


    @state = z.state {
      trip
      routes: routes
    }

  render: =>
    {trip, routes} = @state.getValue()

    console.log routes

    z '.z-edit-trip-choose-route', {
      ontouchstart: (e) -> e.stopPropagation()
      onmousedown: (e) -> e.stopPropagation()
    },
      z @$travelMap
      z '.routes',
        @$elevationChart
