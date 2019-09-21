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

    routes = _map trip.routes, (route) ->
      isHighlighted = not tripRoute or (route.routeId is tripRoute?.routeId)
      {
        routeId: route.routeId
        color: if isHighlighted \
               then colors.getRawColor(colors.$secondary500)
               else colors.getRawColor(colors.$grey500)
        geojson: _flatten _map route.legs, ({route}) ->
          MapService.decodePolyline route.shape
      }

    routes

module.exports = new TripService()
