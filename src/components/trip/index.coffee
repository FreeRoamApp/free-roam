z = require 'zorium'
RxBehaviorSubject = require('rxjs/BehaviorSubject').BehaviorSubject
RxReplaySubject = require('rxjs/ReplaySubject').ReplaySubject
RxObservable = require('rxjs/Observable').Observable
require 'rxjs/add/observable/of'
_map = require 'lodash/map'

Base = require '../base'
PrimaryButton = require '../primary_button'
FlatButton = require '../flat_button'
Map = require '../map'
FormatService = require '../../services/format'
MapService = require '../../services/map'
config = require '../../config'

if window?
  require './index.styl'

module.exports = class EditTrip
  constructor: ({@model, @router, @trip}) ->
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

    mapOptions = {
      @model, @router, places: checkIns, route: route
      initialBounds: [[-156.187, 18.440], [-38.766, 55.152]]
      # preserveDrawingBuffer: true
    }
    @$map = new Map mapOptions

    @state = z.state {
      trip: @trip
      route: route # TODO: rm from state, just send time
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

  render: =>
    {name, checkIns, trip, route} = @state.getValue()

    console.log trip, route

    z '.z-edit-trip',
      z '.map',
        z @$map
        z '.stats',
          "tm: #{FormatService.countdown route?.time}"
      z '.info',
        z '.check-ins',
          _map checkIns, ({checkIn, $addInfoButton}) ->
            z '.check-in', {
            },
              z '.name',
                checkIn.name

              # z '.actions',
              #   if checkIn.id
              #     z $addInfoButton,
              #       text: @model.l.get 'newTrip.addInfo'
              #       hasRipple: false # ripple screws w/ drag drop
              #       onclick: =>
              #         @router.goOverlay 'editCheckIn', {
              #           id: checkIn.id
              #         }
