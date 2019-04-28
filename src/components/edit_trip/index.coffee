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
FlatButton = require '../flat_button'
TravelMap = require '../travel_map'
CheckInTooltip = require '../check_in_tooltip'
LocationSearch = require '../location_search'
DateService = require '../../services/date'
FormatService = require '../../services/format'
config = require '../../config'

if window?
  require './index.styl'

###
# TODO: dialog after sharing asking people to leave reviews, give them list of ones they can add
###

module.exports = class EditTrip extends Base
  constructor: ({@model, @router, @trip}) ->
    @$locationSearch = new LocationSearch {
      @model, @router
      onclick: (location) =>
        @addCheckIn {
          name: location.text
          location: location.location
        }
    }

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
          position: e.point
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
            $addInfoButton: new FlatButton()
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
        z '.overlay',
          z @$locationSearch, {
            placeholder: @model.l.get 'editTrip.searchPlaceholder'
            locationsTitle: @model.l.get 'editTrip.locationsTitle'
          }

        z '.g-grid',
          z '.check-ins',
            if _isEmpty checkIns
              z '.placeholder', @model.l.get 'editTrip.placeHolder'
            _map checkIns, (checkIn) =>
              {checkIn, routeInfo,  $addInfoButton, $attachmentsList} = checkIn
              z '.check-in.draggable', {
                attributes:
                  if @onReorder then {draggable: 'true'} else {}
                dataset:
                  if @onReorder then {id: checkIn.id} else {}
                ondragover: if @onReorder then z.ev (e, $$el) => @onDragOver e
                ondragstart: if @onReorder then z.ev (e, $$el) => @onDragStart e
                ondragend: if @onReorder then z.ev (e, $$el) => @onDragEnd e
              },
                z '.info',
                  z '.name',
                    checkIn.name

                  z '.actions',
                    if checkIn.id
                      z $addInfoButton,
                        text: @model.l.get 'newTrip.addInfo'
                        hasRipple: false # ripple screws w/ drag drop
                        onclick: =>
                          ga? 'send', 'event', 'trip', 'editCheckIn'
                          @router.goOverlay 'editCheckIn', {
                            id: checkIn.id
                          }
                z '.attachments',
                  $attachmentsList

                if routeInfo
                  z '.travel-time',
                    @model.l.get 'editTrip.travelTime'
                    ': '
                    DateService.formatSeconds routeInfo?.time, 1
                    " (#{FormatService.number routeInfo?.distance}mi)"


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
