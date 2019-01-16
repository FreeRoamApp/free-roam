z = require 'zorium'
RxBehaviorSubject = require('rxjs/BehaviorSubject').BehaviorSubject
RxReplaySubject = require('rxjs/ReplaySubject').ReplaySubject
RxObservable = require('rxjs/Observable').Observable
require 'rxjs/add/observable/combineLatest'
require 'rxjs/add/observable/of'
_defaults = require 'lodash/defaults'
_map = require 'lodash/map'
_filter = require 'lodash/filter'
_omit = require 'lodash/omit'

AttachmentsList = require '../attachments_list'
Base = require '../base'
Map = require '../map'
DateService = require '../../services/date'
FormatService = require '../../services/format'
config = require '../../config'

if window?
  require './index.styl'

module.exports = class Trip extends Base
  constructor: ({@model, @router, @trip}) ->
    checkIns = @trip.map (trip) ->
      trip?.checkIns
    # .publishReplay(1).refCount()
    route = @trip.map (trip) ->
      trip?.route
    stats = @trip.map (trip) ->
      trip?.stats

    allStates = @model.trip.getStatesGeoJson()
    allStatesAndStats = RxObservable.combineLatest(
      allStates, stats, (vals...) -> vals
    )
    filledStates = allStatesAndStats.map ([allStates, stats]) ->
      {
        type: 'FeatureCollection'
        features: _filter allStates.features, ({id}) ->
          stats?.stateCounts?[id] > 0
      }

    mapOptions = {
      @model, @router
      usePlaceNumbers: true
      places: checkIns
      route: route
      fill: filledStates
      initialBounds: [[-156.187, 18.440], [-38.766, 55.152]]
      # preserveDrawingBuffer: true
    }
    @$map = new Map mapOptions

    @state = z.state {
      trip: @trip.map (trip) ->
        _omit trip, ['route']
      routeStats: route.map (route) ->
        {time: route?.time, distance: route?.distance}
      checkIns: checkIns.map (checkIns) =>
        _map checkIns, (checkIn) =>
          $attachmentsList = @getCached$(
            "attachmentsList-#{checkIn.id}", AttachmentsList, {
              @model, @router
              attachments: RxObservable.of checkIn.attachments
            }
          )
          {
            checkIn
            $attachmentsList
          }
    }

  render: =>
    {name, checkIns, trip, routeStats} = @state.getValue()

    hasStats = Boolean routeStats?.time

    z '.z-edit-trip', {
      className: z.classKebab {hasStats}
    },
      z '.map',
        z @$map
        z '.stats',
          z '.g-grid',
            z '.time',
              @model.l.get 'trip.totalTime'
              ": #{DateService.formatSeconds routeStats?.time, 1}"
            z '.distance',
              @model.l.get 'trip.totalDistance'
              ": #{FormatService.number routeStats?.distance}mi"
      z '.info',
        z '.g-grid',
          z '.check-ins',
            _map checkIns, ({checkIn, $attachmentsList}) ->
              z '.check-in', {
              },
                z '.info',
                  z '.name',
                    checkIn.name
                z '.attachments',
                  $attachmentsList
