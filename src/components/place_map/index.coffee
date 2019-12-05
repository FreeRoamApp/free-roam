z = require 'zorium'
RxBehaviorSubject = require('rxjs/BehaviorSubject').BehaviorSubject
RxReplaySubject = require('rxjs/ReplaySubject').ReplaySubject
RxObservable = require('rxjs/Observable').Observable
_defaults = require 'lodash/defaults'

Map = require '../map'
colors = require '../../colors'
config = require '../../config'

if window?
  require './index.styl'

module.exports = class PlaceMap
  constructor: (options) ->
    {@model, @router, @place, prepScreenshot} = options

    center = @place.map ({location}) -> location

    @mapSize = new RxBehaviorSubject null
    mapOptions = {
      @model, @router
      place: @place.map (place) ->
        _defaults {
          icon: 'camp'
          fillColor: '#88d7d0'
          strokeColor: colors.getRawColor(colors.$secondary700)
          anchor: 'bottom'
        }, place
      isLargeFocal: true
      places: RxObservable.of [] # @place.map (place) -> [place]
      center: center
      initialZoom: 8
    }
    if prepScreenshot
      mapOptions = _defaults {
        preserveDrawingBuffer: true
        hideControls: true
        # initialBounds: [[-133, 18], [-58, 58]]
        onContentReady: ->
          # screenshotter service waits until this is true
          setTimeout ->
            window.isScreenshotReady = true
          , 1000 # extra time for labels to show
      }, mapOptions

    @$map = new Map mapOptions

    @state = z.state {
      @place
      prepScreenshot
      # routeStats: routes.map (routes) ->
      #   {time: route?.time, distance: route?.distance}
    }

  render: =>
    {prepScreenshot} = @state.getValue()

    console.log 'place map'

    z '.z-place-map',
      z @$map
