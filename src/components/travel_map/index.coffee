z = require 'zorium'
RxBehaviorSubject = require('rxjs/BehaviorSubject').BehaviorSubject
RxObservable = require('rxjs/Observable').Observable
require 'rxjs/add/observable/combineLatest'
require 'rxjs/add/observable/of'
_filter = require 'lodash/filter'
_defaults = require 'lodash/defaults'

Map = require '../map'
ShareMap = require '../share_map'
DateService = require '../../services/date'
FormatService = require '../../services/format'
config = require '../../config'

if window?
  require './index.styl'

module.exports = class TravelMap
  constructor: ({@model, @router, @trip, checkIns, onclick, prepScreenshot}) ->
    checkIns ?= @trip.map (trip) ->
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

    @mapSize = new RxBehaviorSubject null
    mapOptions = {
      @model, @router
      places: checkIns
      route: route
      fill: filledStates
      usePlaceNumbers: true
      initialBounds: [[-156.187, 18.440], [-38.766, 55.152]]
      onclick: onclick
    }
    if prepScreenshot
      mapOptions = _defaults {
        preserveDrawingBuffer: true
        hideLabels: true
        initialBounds: [[-133, 18], [-58, 58]]
        onContentReady: ->
          # screenshotter service waits until this is true
          window.isScreenshotReady = true
      }, mapOptions

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
        console.log 'set prefix', @trip.id, response.prefix
        @model.trip.upsert {
          id: @trip.id
          imagePrefix: response.prefix
        }
    }

    @state = z.state {
      routeStats: route.map (route) ->
        {time: route?.time, distance: route?.distance}
    }

  resetValueStreams: =>
    @clientCheckIns.next []

  share: =>
    ga? 'send', 'event', 'trip', 'share', 'click'
    @$shareMap.share()


  render: =>
    {routeStats} = @state.getValue()

    hasStats = Boolean routeStats?.time

    z '.z-travel-map', {
      className: z.classKebab {hasStats}
    },
      z @$map
      z @$editTripTooltip
      z '.stats',
        z '.g-grid',
          z '.time',
            @model.l.get 'trip.totalTime'
            ": #{DateService.formatSeconds routeStats?.time, 1}"
          z '.distance',
            @model.l.get 'trip.totalDistance'
            ": #{FormatService.number routeStats?.distance}mi"
      z @$shareMap
