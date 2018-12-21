z = require 'zorium'
RxBehaviorSubject = require('rxjs/BehaviorSubject').BehaviorSubject
RxReplaySubject = require('rxjs/ReplaySubject').ReplaySubject
RxObservable = require('rxjs/Observable').Observable
require 'rxjs/add/observable/of'
_map = require 'lodash/map'
_defaults = require 'lodash/defaults'

Base = require '../base'
PrimaryButton = require '../primary_button'
FlatButton = require '../flat_button'
Map = require '../map'
EditTripTooltip = require '../edit_trip_tooltip'
ShareMap = require '../share_map'
LocationSearch = require '../location_search'
DateService = require '../../services/date'
FormatService = require '../../services/format'
MapService = require '../../services/map'
# UiCard = require '../ui_card'
config = require '../../config'

if window?
  require './index.styl'

###
- get pictures
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
    route = serverCheckIns.switchMap (checkIns) =>
      locations = _map checkIns, 'location'
      @model.trip.getRoute {checkIns}
    @clientCheckIns = new RxBehaviorSubject []

    @resetValueStreams()
    checkIns = RxObservable.merge @clientCheckIns, serverCheckIns

    @place = new RxBehaviorSubject null
    @placePosition = new RxBehaviorSubject null
    @mapSize = new RxBehaviorSubject null
    @$editTripTooltip = new EditTripTooltip {
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

    mapOptions = {
      @model, @router, places: checkIns, route: route
      initialBounds: [[-156.187, 18.440], [-38.766, 55.152]]
      onclick: (e) =>
        ga? 'send', 'event', 'trip', 'clickMap'
        @placePosition.next e.point

        latRounded = Math.round(e.lngLat.lat * 1000) / 1000
        lonRounded = Math.round(e.lngLat.lng * 1000) / 1000

        @place.next {
          name: "#{latRounded}, #{lonRounded}"
          type: 'tripCheckIn'
          position: e.point
          location: [e.lngLat.lng, e.lngLat.lat]
        }
    }
    @$map = new Map mapOptions
    @$shareMap = new ShareMap {
      @model, mapOptions
      shareInfo: @trip.map (trip) ->
        {
          text: 'editTrip.shareText'
          url: "#{config.HOST}/trip/#{trip.id}"
        }
      onUpload: (response) =>
        {trip} = @state.getValue()
        @model.trip.upsert {
          id: trip.id
          imagePrefix: response.prefix
        }
    }

    @state = z.state {
      trip: @trip
      route: route # TODO: rm from state
      name: @nameValueStreams.switch()
      checkIns: checkIns.map (checkIns) ->
        _map checkIns, (checkIn) ->
          {
            checkIn
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
    @$shareMap.share()

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
      @model.trip.addCheckIn {
        id: trip.id
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
    {name, checkIns, trip, route} = @state.getValue()

    hasStats = Boolean route?.time

    z '.z-edit-trip', {
      className: z.classKebab {hasStats}
    },
      z '.map',
        z @$map
        z @$editTripTooltip
        z '.stats',
          z '.g-grid',
            z '.time',
              @model.l.get 'trip.totalTime'
              ": #{DateService.formatSeconds route?.time, 1}"
            z '.distance',
              @model.l.get 'trip.totalDistance'
              ": #{FormatService.number route?.distance}mi"
      z '.info',
        z @$locationSearch, {
          placeholder: @model.l.get 'editTrip.searchPlaceholder'
          locationsTitle: @model.l.get 'editTrip.locationsTitle'
          isAppBar: false
        }

        z '.g-grid',
          z '.check-ins',
            _map checkIns, ({checkIn, $addInfoButton}) =>
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

      z @$shareMap
