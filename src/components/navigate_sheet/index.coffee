z = require 'zorium'
_filter = require 'lodash/filter'
_find = require 'lodash/find'
_map = require 'lodash/map'
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

    @state = z.state
      places: places
      trip: trip
      tripRoute: tripRoute
      currentLoading: null

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
          @state.set currentLoading: 'freeRoam'
          {trip, tripRoute} = @state.getValue()
          @model.trip.getMapboxDirectionsByIdAndRouteId(
            trip.id, tripRoute.routeId
          ).take(1).subscribe (directions) =>
            @model.portal.call 'mapbox.setup', {}
            .then =>
              @model.portal.call 'mapbox.navigate', {
                directions: JSON.stringify directions
              }
              @state.set currentLoading: null
        text: 'FreeRoam'
        # $icon: z @$facebookIcon,
        #   icon: 'facebook'
        #   color: FACEBOOK_BLUE
        #   isTouchTarget: false

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
        # $icon: z @$twitterIcon,
        #   icon: 'twitter'
        #   color: TWITTER_BLUE
        #   isTouchTarget: false

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
