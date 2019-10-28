z = require 'zorium'
_filter = require 'lodash/filter'
_find = require 'lodash/find'
_map = require 'lodash/map'
_throttle = require 'lodash/throttle'
RxObservable = require('rxjs/Observable').Observable
require 'rxjs/add/observable/combineLatest'
require 'rxjs/add/observable/of'
colors = require '../../colors'

Icon = require '../icon'
GoogleMapsWarningDialog = require '../google_maps_warning_dialog'
Sheet = require '../sheet'
Environment = require '../../services/environment'
MapService = require '../../services/map'
SemverService = require '../../services/semver'
config = require '../../config'

if window?
  require './index.styl'

THIRTY_SECONDS_MS = 30 * 1000

module.exports = class NavigateSheet
  constructor: ({@model, @router, trip, tripRoute}) ->
    @$sheet = new Sheet {@model, @router}
    # @$twitterIcon = new Icon()
    # @$facebookIcon = new Icon()

    places = RxObservable.combineLatest(
      if trip?.map then trip else RxObservable.of trip
      if tripRoute?.map then tripRoute else RxObservable.of tripRoute
      (trip, tripRoute) ->
        if trip and tripRoute
          start = _find trip.destinationsInfo, {id: tripRoute?.startCheckInId}
          end = _find trip.destinationsInfo, {id: tripRoute?.endCheckInId}
          stops = trip.stops[tripRoute.routeId]
          places = _filter [start?.place].concat stops, [end?.place]
    )

    @currentNavigationRouteId = null
    @lastLocation = null

    @state = z.state
      places: places
      trip: trip
      tripRoute: tripRoute
      currentLoading: null

    @_reroute = _throttle ((tripId, routeId, location) =>
      locationsSimilar = @_locationsSimilar location, @lastLocation
      if @currentNavigationRouteId is routeId and not locationsSimilar
        @lastLocation = location
        @model.portal.call 'mapbox.showSnackBar', {
          text: 'Rerouting...'
        }
        @model.trip.getMapboxDirectionsByIdAndRouteId(
          tripId, routeId, {location}
        ).take(1).subscribe (directions) =>
          @model.portal.call 'mapbox.hideSnackBar'
          @model.portal.call 'mapbox.navigate', {
            directions: JSON.stringify directions
          }
    ), THIRTY_SECONDS_MS, {trailing: false}

  _locationsSimilar: (location1, location2) ->
    lat1 = Math.round(location1?.lat * 1000) / 1000
    lat2 = Math.round(location2?.lat * 1000) / 1000
    lon1 = Math.round(location1?.lon * 1000) / 1000
    lon2 = Math.round(location2?.lon * 1000) / 1000
    lat1 is lat2 and lon1 is lon2

  render: =>
    {currentLoading, places} = @state.getValue()

    isNative = Environment.isNativeApp 'freeroam'
    appVersion = isNative and Environment.getAppVersion(
      'freeroam'
    )

    options =
      freeRoam:
        isVisible: isNative and SemverService.gte appVersion, '2.0.06'
        onclick: =>
          {trip, tripRoute, currentLoading} = @state.getValue()
          if currentLoading is 'freeRoam'
            return
          @state.set currentLoading: 'freeRoam'
          MapService.getLocation {@model}
          .catch -> null
          .then (location) =>
            @model.trip.getMapboxDirectionsByIdAndRouteId(
              # don't use location here. ideally user is on route.
              # if not, it'll update as off-route
              trip.id, tripRoute.routeId#, {location}
            ).take(1).subscribe (directions) =>
              Promise.all [
                @model.portal.call 'mapbox.setup', {}
                @model.portal.call 'mapbox.clearEventListeners'
                .then =>
                  @model.portal.call 'mapbox.onEvent', ({ev, data}) =>
                    data = try
                      JSON.parse data
                    catch
                      {}
                    if ev is 'offRoute'
                      @currentNavigationRouteId = tripRoute.routeId
                      @_reroute(trip.id, tripRoute.routeId, data)
                    else if ev in ['navigationCancel', 'navigationFinished']
                      @lastLocation = null
                      @currentNavigationRouteId = null
              ]
              .then =>
                @model.portal.call 'mapbox.navigate', {
                  directions: JSON.stringify directions
                }
                @state.set currentLoading: null
        text: 'FreeRoam'

      googleMaps:
        isVisible: true
        onclick: =>
          {places} = @state.getValue()
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
        text: 'Google Maps'

      # waze:
      #   isVisible: true
      #   onclick: =>
      #     {places} = @state.getValue()
      #     go = =>
      #       MapService.getDirectionsBetweenPlaces(
      #         places
      #         {@model}
      #       )
      #     if @model.cookie.get('hasSeenGoogleMapsWarning')
      #       go()
      #     else
      #       @model.cookie.set 'hasSeenGoogleMapsWarning', '1'
      #       @model.overlay.open new GoogleMapsWarningDialog({@model}), {
      #         onComplete: go
      #         onCancel: go
      #       }
      #   text: 'Waze'

    z '.z-navigate-sheet',
      z @$sheet,
        $content:
          z '.z-navigate-sheet_sheet',
            z '.title', 'Navigate'
            _map options, (option, type) ->
              unless option.isVisible
                return

              z '.item', {
                onclick: option.onclick
              },
                # z '.icon',
                #   option.$icon
                z '.text', if currentLoading is type \
                           then 'Loading...'
                           else option.text
