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
    routes.push {
      geojson: allGeojson, color: colors.getRawColor(colors.$primary500)
    }
    highlightedRoute = _find trip.routes, {id: tripRoute?.id}
    if highlightedRoute
      highlightedGeojson = _flatten _map highlightedRoute?.legs, ({route}) ->
        MapService.decodePolyline route.shape
      routes.push {
        geojson: highlightedGeojson
        color: colors.getRawColor(colors.$secondary500)
      }

    routes

module.exports = new TripService()
