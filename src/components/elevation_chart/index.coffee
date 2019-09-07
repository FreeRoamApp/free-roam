z = require 'zorium'
_map = require 'lodash/map'
_maxBy = require 'lodash/maxBy'
_minBy = require 'lodash/minBy'
RxBehaviorSubject = require('rxjs/BehaviorSubject').BehaviorSubject

colors = require '../../colors'

if window?
  require './index.styl'

module.exports = class ElevationChart
  constructor: ({@model, routes}) ->
    @size = new RxBehaviorSubject null

    @state = z.state {
      routes
      @size
    }

  afterMount: (@$$el) =>
    @subscribeToResize()

  beforeUnmount: =>
    @resizeSubscription?.unsubscribe()

  # TODO: maybe move this to base component since it's used in a few places?
  subscribeToResize: =>
    setTimeout =>
      checkIsReady = =>
        if @$$el and @$$el.offsetWidth
          @resizeSubscription = @model.window.getSize().subscribe =>
            setTimeout =>
              @size?.next {
                width: @$$el.offsetWidth
                height: @$$el.offsetHeight
                padding: 16
              }
            , 0
        else
          setTimeout checkIsReady, 100
      checkIsReady()
    , 0 # give time for re-render...

  getPoints: (route) =>
    {size} = @state.getValue()
    {width, height, padding} = size or {}

    elevations = route?.elevations
    minRange = _minBy(elevations, ([range, elevation]) -> range)?[0]
    maxRange = _maxBy(elevations, ([range, elevation]) -> range)?[0]

    minElevation = _minBy(elevations, ([range, elevation]) -> elevation)?[1]
    maxElevation = _maxBy(elevations, ([range, elevation]) -> elevation)?[1]
    rangeElevation = maxElevation - minElevation

    _map elevations, ([range, elevation], i) =>
      height - (padding + ((elevation - minElevation) / rangeElevation) * (height - padding * 2))
      [
        (padding + (range / maxRange) * (width - padding * 2))
        height - (padding + ((elevation - minElevation) / rangeElevation) * (height - padding * 2))
      ]

  render: ({heightRatio}) =>
    {routes, size} = @state.getValue()

    {width, height, padding} = size or {}

    mainRoute = routes?[0]

    points = @getPoints mainRoute
    alternativePoints = @getPoints routes?[1]

    z '.z-elevation-chart', {
      key: 'elevation-chart'
      # style:
        # width: "#{width}px"
        # height: "#{height}px"
    },
      z 'svg', {
        key: 'elevation-chart'
        namespace: 'http://www.w3.org/2000/svg'
        attributes:
          'viewBox': "0 0 #{width} #{height}"
        style:
          width: "#{width}px"
          height: "#{height}px"
      },
        z 'text', {
          namespace: 'http://www.w3.org/2000/svg'
          attributes:
            x: width - padding
            y: padding
            'text-anchor': 'end'
        },
          "#{mainRoute?.elevationStats.max} "
          @model.l.get 'editTripSettings.feetAbbr'

        z 'text', {
          namespace: 'http://www.w3.org/2000/svg'
          attributes:
            x: width - padding
            y: height - padding
            'text-anchor': 'end'
        },
          "#{mainRoute?.elevationStats.min} "
          @model.l.get 'editTripSettings.feetAbbr'

        z 'polyline', {
          namespace: 'http://www.w3.org/2000/svg'
          attributes:
            fill: 'none'
            stroke: colors.$secondary500
            'stroke-width': 4
            points: points.join ' '
        }
        # fill
        z 'polyline', {
          namespace: 'http://www.w3.org/2000/svg'
          attributes:
            fill: colors.$secondary500
            stroke: 'none'
            'fill-opacity': 0.12
            points: points.concat [
              [width - padding, height - padding]
              [padding, height - padding]
            ]
            .join ' '
        }

        z 'polyline', {
          namespace: 'http://www.w3.org/2000/svg'
          attributes:
            fill: 'none'
            stroke: colors.$grey500
            'stroke-width': 4
            'stroke-dasharray': '10,10'
            points: alternativePoints.join ' '
        }
