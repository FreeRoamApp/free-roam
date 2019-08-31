RxObservable = require('rxjs/Observable').Observable
require 'rxjs/add/observable/never'
_flatten = require 'lodash/flatten'
_find = require 'lodash/find'
_map = require 'lodash/map'

MapService = require './map'
colors = require '../colors'

class TripService
  getRouteGeoJson: (trip, tripRoute) ->
    unless trip
      return RxObservable.never()
    routes = []
    allGeojson = _flatten _map trip.routes, (route) ->
      _flatten _map route.legs, ({route}) ->
        MapService.decodePolyline route.shape

    highlightedRoute = _find trip.routes, {id: tripRoute?.id}

    routes.push {
      geojson: allGeojson
      color: if highlightedRoute \
             then colors.getRawColor(colors.$grey500)
             else colors.getRawColor(colors.$secondary500)
    }
    if highlightedRoute
      highlightedGeojson = _flatten _map highlightedRoute?.legs, ({route}) ->
        MapService.decodePolyline route.shape
      routes.push {
        geojson: highlightedGeojson
        color: colors.getRawColor(colors.$secondary500)
      }

    routes

module.exports = new TripService()
