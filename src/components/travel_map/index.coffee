z = require 'zorium'
RxBehaviorSubject = require('rxjs/BehaviorSubject').BehaviorSubject
RxObservable = require('rxjs/Observable').Observable
require 'rxjs/add/observable/combineLatest'
require 'rxjs/add/observable/of'
_filter = require 'lodash/filter'
_defaults = require 'lodash/defaults'

Map = require '../map'
ShareMapDialog = require '../share_map_dialog'
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
      initialBounds: [[-141.187, 18.440], [-53.766, 55.152]]
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

    @$shareMapDialog = new ShareMapDialog {
      @model, @trip
      shareInfo: @trip.map (trip) =>
        {
          text: @model.l.get 'trip.shareText'
          url: "#{config.HOST}/trip/#{trip.id}"
        }
    }

    @state = z.state {
      prepScreenshot
      routeStats: route.map (route) ->
        {time: route?.time, distance: route?.distance}
    }

  resetValueStreams: =>
    @clientCheckIns.next []

  share: =>
    ga? 'send', 'event', 'trip', 'share', 'click'
    @model.overlay.open @$shareMapDialog


  render: =>
    {routeStats, prepScreenshot} = @state.getValue()

    hasStats = Boolean routeStats?.time

    z '.z-travel-map', {
      className: z.classKebab {hasStats}
    },
      z @$map
      z @$tripTooltip
      if prepScreenshot
          z '.stats',
            z '.g-grid',
              z '.time',
                @model.l.get 'trip.totalTime'
                ": #{DateService.formatSeconds routeStats?.time, 1}"
              z '.distance',
                @model.l.get 'trip.totalDistance'
                ": #{FormatService.number routeStats?.distance}mi"
      z @$shareMap
