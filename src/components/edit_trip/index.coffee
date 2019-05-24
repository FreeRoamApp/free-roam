z = require 'zorium'
RxBehaviorSubject = require('rxjs/BehaviorSubject').BehaviorSubject
RxReplaySubject = require('rxjs/ReplaySubject').ReplaySubject
RxObservable = require('rxjs/Observable').Observable
require 'rxjs/add/observable/combineLatest'
require 'rxjs/add/observable/of'
_map = require 'lodash/map'
_defaults = require 'lodash/defaults'
_isEmpty = require 'lodash/isEmpty'
_omit = require 'lodash/omit'

Base = require '../base'
AttachmentsList = require '../attachments_list'
Fab = require '../fab'
Icon = require '../icon'
TravelMap = require '../travel_map'
CheckInTooltip = require '../check_in_tooltip'
DateService = require '../../services/date'
FormatService = require '../../services/format'
colors = require '../../colors'
config = require '../../config'

if window?
  require './index.styl'

###
# TODO: dialog after sharing asking people to leave reviews, give them list of ones they can add
###

module.exports = class EditTrip extends Base
  constructor: ({@model, @router, @trip}) ->
    @$addFab = new Fab()

    @nameValueStreams = new RxReplaySubject 1

    serverCheckIns = @trip.map (trip) ->
      trip?.checkIns
    # .publishReplay(1).refCount()
    @clientCheckIns = new RxBehaviorSubject []
    @resetValueStreams()
    checkIns = RxObservable.merge @clientCheckIns, serverCheckIns
    checkInsAndTrip = RxObservable.combineLatest(
      checkIns, @trip, (vals...) -> vals
    )

    @place = new RxBehaviorSubject null
    @placePosition = new RxBehaviorSubject null
    @mapSize = new RxBehaviorSubject null
    @$checkInTooltip = new CheckInTooltip {
      @model, @router, @place, position: @placePosition, @mapSize
      onSave: (place) =>
        @addCheckIn _defaults {
          location:
            lat: place.location[1]
            lon: place.location[0]
        }, place
        .then =>
          @place.next null
    }


    @$travelMap = new TravelMap {
      @model, @router, @trip, checkIns
      onclick: (e) =>
        ga? 'send', 'event', 'trip', 'clickMap'
        @placePosition.next e.point

        latRounded = Math.round(e.lngLat.lat * 10000) / 10000
        lonRounded = Math.round(e.lngLat.lng * 10000) / 10000

        @place.next {
          name: "#{latRounded}, #{lonRounded}"
          type: 'tripCheckIn'
          location: [e.lngLat.lng, e.lngLat.lat]
        }
    }

    @state = z.state {
      trip: @trip.map (trip) ->
        _omit trip, ['route']
      name: @nameValueStreams.switch()
      checkIns: checkInsAndTrip.map ([checkIns, trip]) =>
        _map checkIns, (checkIn, i) =>
          # doesn't update when new attachments added
          # $attachmentsList = @getCached$(
          #   "attachmentsList-#{checkIn.id}", AttachmentsList, {
          #     @model, @router
          #     attachments: RxObservable.of checkIn.attachments
          #   }
          # )
          {
            checkIn
            routeInfo: if trip.route?.legs?[i]
              _omit trip.route.legs[i], ['shape']
            $attachmentsList: new AttachmentsList {
              @model, @router
              attachments: RxObservable.of checkIn.attachments
            }
            $moreIcon: new Icon()
          }
    }

  resetValueStreams: =>
    @clientCheckIns.next []

    if @trip
      @nameValueStreams.next @trip.map (trip) ->
        trip?.name or ''
    else
      @nameValueStreams.next new RxBehaviorSubject ''

  save: =>
    {name, checkIns} = @state.getValue()

    @model.trip.upsert {
      name
      checkIns
    }

  share: =>
    ga? 'send', 'event', 'trip', 'share', 'click'
    @$travelMap.share()

  addCheckIn: (checkIn) =>
    ga? 'send', 'event', 'trip', 'share', 'addCheckIn', checkIn.name
    {trip, checkIns} = @state.getValue()
    checkIns = _map checkIns, 'checkIn'
    newCheckIns = checkIns.concat checkIn
    # TODO: create CheckIn, show loading while id doesn't exist
    # @checkInsValueStreams.next RxObservable.of newCheckIns
    @clientCheckIns.next newCheckIns

    @model.coordinate.upsert {
      name: checkIn.name
      location: "#{checkIn.location.lat}, #{checkIn.location.lon}"
    }, {invalidateAll: false}
    .then ({id}) =>
      @model.checkIn.upsert {
        tripIds: [trip.id]
        name: checkIn.name
        sourceType: 'coordinate'
        sourceId: id
        setUserLocation: trip.type is 'past'
      }

  onReorder: (ids) =>
    ga? 'send', 'event', 'trip', 'reorder'
    {trip} = @state.getValue()
    @model.trip.upsert {
      id: trip.id
      checkInIds: ids
    }

  render: =>
    {name, checkIns, trip} = @state.getValue()

    z '.z-edit-trip',
      z '.map',
        z @$travelMap
        z @$checkInTooltip,
          buttonText: @model.l.get 'editTripTooltip.addToTrip'

        if checkIns?.length > 1
          z '.places-along-route', {
            onclick: =>
              @router.go 'home', null, {
                qs:
                  tripId: trip.id
              }
          },
            @model.l.get 'editTrip.findAlongRoute'
      z '.info',
        z '.g-grid',
          z '.add', {
            onclick: =>
              @router.go 'newCheckIn', {
                tripType: trip.type
                tripId: trip.id
              }
          },
            z @$addFab,
              isSecondary: true
              icon: 'add'
              onclick: =>
                @router.go 'newCheckIn', {
                  tripType: trip.type
                  tripId: trip.id
                }
            z '.text',
              @model.l.get 'editTrip.addLocation'
          z '.check-ins',
            [
              if _isEmpty checkIns
                z '.placeholder', @model.l.get 'editTrip.placeHolder'
              else
                z '.divider'
              _map checkIns, (checkIn, i) =>
                {checkIn, routeInfo,  $moreIcon, $attachmentsList} = checkIn
                z '.check-in.draggable', {
                  onclick: =>
                    ga? 'send', 'event', 'trip', 'editCheckIn'
                    @router.goOverlay 'editCheckIn', {
                      id: checkIn.id
                    }
                  attributes:
                    if @onReorder then {draggable: 'true'} else {}
                  dataset:
                    if @onReorder then {id: checkIn.id} else {}
                  ondragover: if @onReorder then z.ev (e, $$el) =>
                    @onDragOver e
                  ondragstart: if @onReorder then z.ev (e, $$el) =>
                    @onDragStart e
                  ondragend: if @onReorder then z.ev (e, $$el) =>
                    @onDragEnd e
                },
                  z '.time',
                    z '.date', 'time'
                    if routeInfo
                      z '.travel-time',
                        z 'div',
                          "#{DateService.formatSeconds routeInfo?.time, 1} /"
                        z 'div',
                          "#{FormatService.number routeInfo?.distance}mi"


                  z '.dot'
                  z '.info',
                    z '.name',
                      "#{checkIns.length - i}. #{checkIn.name}"
                    z '.attachments',
                      $attachmentsList

                  z '.actions',
                    if checkIn.id
                      z $moreIcon,
                        icon: 'chevron-right'
                        isTouchTarget: false
                        color: colors.$secondary500

            ]

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
