z = require 'zorium'
RxBehaviorSubject = require('rxjs/BehaviorSubject').BehaviorSubject
RxReplaySubject = require('rxjs/ReplaySubject').ReplaySubject
RxObservable = require('rxjs/Observable').Observable
require 'rxjs/add/observable/combineLatest'
require 'rxjs/add/observable/of'
_clone = require 'lodash/clone'
_map = require 'lodash/map'
_filter = require 'lodash/filter'
_defaults = require 'lodash/defaults'
_isEmpty = require 'lodash/isEmpty'
_omit = require 'lodash/omit'
_reduce = require 'lodash/reduce'
_sumBy = require 'lodash/sumBy'
_uniq = require 'lodash/uniq'

Base = require '../base'
PlaceListItem = require '../place_list_item'
Icon = require '../icon'
CheckInTooltip = require '../check_in_tooltip'
NavigateSheet = require '../navigate_sheet'
PrimaryButton = require '../primary_button'
Spinner = require '../spinner'
DateService = require '../../services/date'
FormatService = require '../../services/format'
MapService = require '../../services/map'
colors = require '../../colors'
config = require '../../config'

if window?
  require './index.styl'

###
# TODO: dialog after sharing asking people to leave reviews, give them list of ones they can add
###

module.exports = class TripItinerary extends Base
  constructor: ({@model, @router, @trip, destinations}) ->
    @visibleRouteIds = new RxBehaviorSubject []
    tripAndVisibleRouteIds = RxObservable.combineLatest(
      @trip, @visibleRouteIds, (vals...) -> vals
    )
    stops = tripAndVisibleRouteIds.switchMap ([trip, routeIds]) =>
      if trip?.id and not _isEmpty routeIds
        @model.trip.getRouteStopsByTripIdAndRouteIds trip.id, routeIds
        .map (stops) ->
          # make sure even if no stops for routeId, return false (for spinner)
          _reduce routeIds, (obj, routeId) ->
              obj[routeId] = stops?[routeId] or false
              obj
          , {}
      else
        RxObservable.of false

    destinationsAndTripAndStops = RxObservable.combineLatest(
      destinations, @trip, stops, (vals...) -> vals
    )

    @$spinner = new Spinner()

    @state = z.state {
      me: @model.user.getMe()
      visibleRouteIds: @visibleRouteIds
      trip: @trip.map (trip) ->
        _omit trip, ['route']
      destinations: destinationsAndTripAndStops
      .map ([destinations, trip, stops]) =>
        if _isEmpty destinations
          return false

        _map destinations, (destination, i) =>
          if _isEmpty destination.attachments
            id = destination.id
          else
            id = _map(destination.attachments, 'id').join(',')

          routeInfo = trip.routes[i]
          routeInfo?.time = _sumBy routeInfo?.legs, ({route}) ->
            route.time
          routeInfo?.distance = _sumBy routeInfo?.legs, ({route}) ->
            route.distance

          if stops?[routeInfo?.routeId]?
            stopsInfo = _map stops?[routeInfo?.routeId], (stop) =>
              stopCacheKey = "stop-#{stop.id}"
              {
                stop
                $deleteIcon: new Icon()
                $place: @getCached$ stopCacheKey, PlaceListItem, {
                  @model, @router, place: stop.place, name: stop.name
                }
              }
          else
            stopsInfo = null

          destinationCacheKey = "destination-#{destination.id}"
          {
            destination
            routeInfo: routeInfo
            stopsInfo: stopsInfo
            $place: @getCached$ destinationCacheKey, PlaceListItem, {
              @model, @router, place: destination.place, name: destination.name
            }
            $chevronIcon: new Icon()
            $routeIcon: new Icon()
            $navigateButton: new PrimaryButton()
            $addStopButton: new PrimaryButton()
            $spinner: new Spinner()
          }
    }

  # onReorder: (ids) =>
  #   ga? 'send', 'event', 'trip', 'reorder'
  #   {trip} = @state.getValue()
  #   @model.trip.upsert {
  #     id: trip.id
  #     checkInIds: ids # _clone(ids).reverse()
  #   }

  render: =>
    {me, destinations, trip, visibleRouteIds} = @state.getValue()

    hasEditPermission = @model.trip.hasEditPermission trip, me

    z '.z-trip-itinerary',
      z '.g-grid',
        z '.check-ins',
          [
            if destinations is false
              z '.placeholder',
                z '.icon'
                z '.title', @model.l.get 'trip.placeHolderTitle'
                z '.description', @model.l.get 'trip.placeHolderDescription'
            else if destinations
              z '.divider'
            else
              z @$spinner
            _map destinations, (destination, i) =>
              {destination, stopsInfo, routeInfo, $chevronIcon, $routeIcon,
                $place, $navigateButton, $addStopButton, $spinner} = destination

              location = @model.checkIn.getLocation destination

              previousDestination = destinations[i - 1]?.destination

              z '.check-in', {
                # attributes:
                #   if @onReorder then {draggable: 'true'} else {}
                # dataset:
                #   if @onReorder then {id: checkIn.id} else {}
                # ondragover: if @onReorder then z.ev (e, $$el) =>
                #   @onDragOver e
                # ondragstart: if @onReorder then z.ev (e, $$el) =>
                #   @onDragStart e
                # ondragend: if @onReorder then z.ev (e, $$el) =>
                #   @onDragEnd e
              },
                z '.dot'
                z '.info',
                  z '.dates',
                    z '.date',
                      if destination.startTime
                        DateService.format(
                          new Date(destination.startTime), 'MMM D'
                        )
                  z '.place-list-item', {
                    onclick: =>
                      @router.goOverlay 'checkIn', {
                        id: destination.id
                      }
                  },
                    z $place

                  if routeInfo
                    hasVisibleStops =
                      visibleRouteIds.indexOf(routeInfo.routeId) isnt -1

                    z '.route',
                      z '.header',
                        z '.plan-route', {
                          onclick: =>
                            if hasVisibleStops
                              @visibleRouteIds.next(
                                _filter visibleRouteIds, (routeId) ->
                                  routeId isnt routeInfo.routeId
                              )
                            else
                              @visibleRouteIds.next(
                                _uniq visibleRouteIds.concat [routeInfo.routeId]
                              )
                        },
                          z '.text', @model.l.get 'tripItinerary.planThisRoute'
                          z '.icon',
                            z $chevronIcon,
                              icon: if hasVisibleStops \
                                    then 'chevron-down'
                                    else 'chevron-up'
                              isTouchTarget: false
                              color: colors.$bgText54
                        z '.travel-time', {
                          # onclick: (e) =>
                          #   e.stopPropagation()
                          #   @router.go 'editTripRouteInfo', {
                          #     id: trip?.id
                          #     routeId: routeInfo?.routeId
                          #   }
                        },
                          z '.icon',
                            z $routeIcon,
                              icon: 'road'
                              isTouchTarget: false
                              size: '16px'
                              color: colors.$bgText54
                          "#{FormatService.number routeInfo?.distance}mi, "
                          "#{DateService.formatSeconds routeInfo?.time, 1}"
                      z '.content', {
                        className:
                          z.classKebab {isVisible: hasVisibleStops}
                      },
                        unless stopsInfo?
                          z $spinner
                        else
                          [
                            z '.stops',
                              _map stopsInfo, ({stop, $place, $deleteIcon}) =>
                                z '.stop', {
                                  onclick: =>
                                    @router.goOverlay 'checkIn', {
                                      id: stop.id
                                    }
                                },
                                  z $place
                                  z '.delete',
                                    z $deleteIcon,
                                      icon: 'delete'
                                      color: colors.$bgText54
                                      onclick: (e) =>
                                        e?.stopPropagation()
                                        if confirm @model.l.get 'general.confirm'
                                          @model.trip.deleteStopByIdAndRouteId(
                                            trip.id
                                            routeInfo.routeId
                                            stop.id
                                          )
                            z '.actions',
                              z '.action',
                                z $navigateButton,
                                  text: @model.l.get 'tripItinerary.navigate'
                                  isOutline: true
                                  onclick: =>
                                    @model.overlay.open new NavigateSheet {
                                      @model
                                      @router
                                      trip
                                      tripRoute: routeInfo
                                    }
                              z '.action',
                                z $addStopButton,
                                  text: @model.l.get 'tripItinerary.addStop'
                                  onclick: =>
                                    @router.go 'editTripAddStop', {
                                      id: trip?.id
                                      routeId: routeInfo?.routeId
                                    }
                          ]

          ]
