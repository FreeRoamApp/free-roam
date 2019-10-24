z = require 'zorium'
RxBehaviorSubject = require('rxjs/BehaviorSubject').BehaviorSubject
RxReplaySubject = require('rxjs/ReplaySubject').ReplaySubject
RxObservable = require('rxjs/Observable').Observable
require 'rxjs/add/observable/combineLatest'
_find = require 'lodash/find'
_filter = require 'lodash/filter'
_map = require 'lodash/map'

TravelMap = require '../travel_map'
EditTripRouteInfoElevation = require '../edit_trip_route_info_elevation'
EditTripRouteInfoSettings = require '../edit_trip_route_info_settings'
Icon = require '../icon'
Tabs = require '../tabs'
SecondaryButton = require '../secondary_button'
PrimaryButton = require '../primary_button'
GoogleMapsWarningDialog = require '../google_maps_warning_dialog'
NavigateSheet = require '../navigate_sheet'
DateService = require '../../services/date'
FormatService = require '../../services/format'
MapService = require '../../services/map'
colors = require '../../colors'
config = require '../../config'

if window?
  require './index.styl'

module.exports = class EditTripRouteInfo
  constructor: (options) ->
    {@model, @router, trip, tripRoute, tripAndTripRoute, waypoints
      routesStreams, destinationsStreams, @isEditingRoute,
      @selectedRoute, routeFocus} = options
    # for changing route
    waypoints ?= new RxBehaviorSubject []

    avoidHighwaysStreams = new RxReplaySubject 1
    avoidHighwaysStreams.next tripRoute.map (tripRoute) ->
      tripRoute?.settings?.avoidHighways
    useTruckRouteStreams = new RxReplaySubject 1
    useTruckRouteStreams.next tripRoute.map (tripRoute) ->
      tripRoute?.settings?.useTruckRoute

    tripAndTripRouteAndWaypointsAndSettings = RxObservable.combineLatest(
      trip, tripRoute, waypoints, avoidHighwaysStreams.switch()
      useTruckRouteStreams.switch(), @isEditingRoute, (vals...) -> vals
    )

    routes = tripAndTripRouteAndWaypointsAndSettings.switchMap (obj) =>
      [trip, tripRoute, wp, avoidHighways, useTruckRoute, isEditingRoute] = obj

      if tripRoute
        @model.trip.getRoutesByIdAndRouteId trip.id, tripRoute.routeId, {
          waypoints: wp
          avoidHighways, useTruckRoute, isEditingRoute
        }
      else
        RxObservable.of null

    routesStreams.next routes.map (routes) ->
      routes = _map routes, ({routeId, routeSlug, shape}, i) ->
        {
          routeId: routeId
          routeSlug: routeSlug
          geojson: MapService.decodePolyline shape
          color:
            if i is 0
            then colors.getRawColor(colors.$secondaryMain)
            else colors.getRawColor(colors.$grey500)
        }
      routes.reverse()
      routes

    destinationsStreams.next waypoints.map (wp) ->
      _map wp, (point, i) ->
        {
          name: "Stop (#{i})" # index used to remove when tapped again
          location: point
          number: ''
          icon: 'drop_pin'
          anchor: 'center'
          type: 'waypoint'
        }

    @$tabs = new Tabs {@model}

    @$editTripRouteInfoElevation = new EditTripRouteInfoElevation {
      @model, routes, routeFocus
    }

    @$editTripRouteInfoSettings = new EditTripRouteInfoSettings {
      @model, avoidHighwaysStreams, useTruckRouteStreams, @isEditingRoute
    }

    @$headerIcon = new Icon()
    @$headerCloseIcon = new Icon()

    @$saveRouteButton = new SecondaryButton()
    @$googleMapsButton = new PrimaryButton()

    @isOpen = new RxBehaviorSubject false

    @state = z.state {
      trip
      tripRoute
      @isEditingRoute
      waypoints
      @isOpen
      isSaving: false
      avoidHighways: avoidHighwaysStreams.switch()
      useTruckRoute: useTruckRouteStreams.switch()
      start: tripAndTripRoute.map ([trip, tripRoute]) ->
        _find trip.destinationsInfo, {id: tripRoute?.startCheckInId}
      end: tripAndTripRoute.map ([trip, tripRoute]) ->
        _find trip.destinationsInfo, {id: tripRoute?.endCheckInId}
      routes: routes
    }

  beforeUnmount: =>
    @isEditingRoute.next false

  render: =>
    {start, end, isEditingRoute, trip, tripRoute, routes, isOpen, isSaving
      avoidHighways, useTruckRoute, waypoints} = @state.getValue()

    stops = trip?.stops[tripRoute?.routeId]

    places = _filter [start?.place].concat stops, [end?.place]

    mainRoute = routes?[0]
    altRoute = routes?[1]

    if not tripRoute
      z '.edit-trip-route-info'
    else
      z '.z-edit-trip-route-info', {
        className: z.classKebab {isOpen}
        ontouchstart: (e) -> e.stopPropagation()
        onmousedown: (e) -> e.stopPropagation()
      },
        z '.header', {
          onclick: =>
            @isOpen.next not isOpen
        },
          z '.text',
            if isOpen
              @model.l.get 'editTripRouteInfo.headerHide'
            else
              @model.l.get 'editTripRouteInfo.headerOpen'
          z '.icon',
            z @$headerIcon,
              icon: if isOpen then 'chevron-down' else 'chevron-up'
              isTouchTarget: false
              color: if isOpen \
                     then colors.$bgText54
                     else colors.$primaryMainText
          z '.close-icon',
            z @$headerCloseIcon,
             icon: 'close'
             isTouchTarget: false
             color: if isOpen \
                    then colors.$bgText54
                    else colors.$primaryMainText
             onclick: (e) =>
               e?.stopPropagation()
               @selectedRoute.next null
        if isOpen
          [
            z @$tabs,
              isBarFixed: false
              tabs: [
                {
                  $menuText: @model.l.get 'editTripRouteInfo.info'
                  $el: @$editTripRouteInfoElevation
                }
                {
                  $menuText: @model.l.get 'editTripRouteInfo.editRoute'
                  $el: @$editTripRouteInfoSettings
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
                if isEditingRoute
                  z @$saveRouteButton,
                    text: if isSaving \
                          then @model.l.get 'general.saving'
                          else @model.l.get 'editTripRouteInfo.saveRoute'
                    onclick: =>
                      if isSaving
                        return
                      @state.set isSaving: true
                      @model.trip.setRouteByIdAndRouteId(
                        trip.id, tripRoute.routeId, {
                          isEditingRoute, avoidHighways, useTruckRoute, waypoints
                        }
                      )
                      .then =>
                        # TODO: not sure why this is needed, but w/o,
                        # sometimes alt route stays up
                        setTimeout =>
                          @isEditingRoute.next false
                        , 0
                        @state.set isSaving: false
                else
                  z @$googleMapsButton,
                    text: @model.l.get 'tripItinerary.navigate'
                    onclick: =>
                      @model.overlay.open new NavigateSheet {
                        @model
                        @router
                        trip
                        tripRoute
                      }

          ]
