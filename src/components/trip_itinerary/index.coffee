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
_sumBy = require 'lodash/sumBy'
_uniq = require 'lodash/uniq'

Base = require '../base'
PlaceListItem = require '../place_list_item'
Icon = require '../icon'
CheckInTooltip = require '../check_in_tooltip'
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
      else
        RxObservable.of null

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

          stopsInfo = _map stops?[routeInfo?.id], (stop) =>
            stopCacheKey = "stop-#{stop.id}"
            {
              stop
              $place: @getCached$ stopCacheKey, PlaceListItem, {
                @model, @router, place: stop.place, name: stop.name
              }
            }

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
            $chooseRouteButton: new PrimaryButton()
            $addStopButton: new PrimaryButton()
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
                $place, $chooseRouteButton, $addStopButton} = destination

              location = @model.checkIn.getLocation destination

              previousDestination = destinations[i - 1]?.destination

              z '.check-in.draggable', {
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
                    hasVisibleStops = true or not _isEmpty stopsInfo
                    # TODO: dynamically load stops when expanding
                    z '.route',
                      z '.header',
                        z '.en-route', {
                          onclick: =>
                            if hasVisibleStops
                              @visibleRouteIds.next(
                                _filter visibleRouteIds, (routeId) ->
                                  routeId isnt routeInfo.id
                              )
                            else
                              @visibleRouteIds.next(
                                _uniq visibleRouteIds.concat [routeInfo.id]
                              )
                        },
                          z '.text', @model.l.get 'tripItinerary.enRoute'
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
                          #   MapService.getDirectionsBetweenPlaces(
                          #     previousDestination.place
                          #     destination.place
                          #     {@model}
                          #   )
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
                        z '.stops',
                          _map stopsInfo, ({stop, $place}) ->
                            z $place
                        z $addStopButton,
                          text: @model.l.get 'tripItinerary.addStop'
                          onclick: =>
                            @router.go 'editTripAddStop', {
                              id: trip?.id
                              routeId: routeInfo?.id
                            }

          ]

        if hasEditPermission and not _isEmpty destinations
          z '.privacy', {
            onclick: =>
              @model.trip.upsert {
                id: trip.id
                privacy: if trip?.privacy is 'private' \
                         then 'public'
                         else 'private'
              }
          },
            "#{@model.l.get 'general.privacy'}: #{trip?.privacy or 'public'}"
