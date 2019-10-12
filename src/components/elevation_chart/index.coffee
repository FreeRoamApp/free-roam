z = require 'zorium'
_map = require 'lodash/map'
_maxBy = require 'lodash/maxBy'
_minBy = require 'lodash/minBy'
_max = require 'lodash/max'
_min = require 'lodash/min'
_find = require 'lodash/find'
_reduce = require 'lodash/reduce'
geodist = require 'geodist'
RxBehaviorSubject = require('rxjs/BehaviorSubject').BehaviorSubject

MapService = require '../../services/map'
colors = require '../../colors'

if window?
  require './index.styl'

module.exports = class ElevationChart
  constructor: ({@model, routes, @routeFocus}) ->
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

  getScale: (route1, route2) ->
    elevations = (route1?.elevations or []).concat(route2?.elevations or [])
    minRange = _minBy(elevations, ([range, elevation]) -> range)?[0]
    maxRange = _maxBy(elevations, ([range, elevation]) -> range)?[0]
    rangeRange = maxRange - minRange

    minElevation = _minBy(elevations, ([range, elevation]) -> elevation)?[1]
    maxElevation = _maxBy(elevations, ([range, elevation]) -> elevation)?[1]
    rangeElevation = maxElevation - minElevation
    {minRange, maxRange, rangeRange, minElevation, maxElevation, rangeElevation}

  getPoints: (route, scale) =>
    {size} = @state.getValue()
    {width, height, padding} = size or {}
    {minRange, maxRange, minElevation, maxElevation, rangeElevation} = scale
    elevations = route?.elevations

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
    altRoute = routes?[1]

    scale = @getScale mainRoute, routes?[1]

    points = @getPoints mainRoute, scale
    alternativePoints = @getPoints altRoute, scale

    max = _max [mainRoute?.elevationStats.max, altRoute?.elevationStats.max]
    min = _min [mainRoute?.elevationStats.min, altRoute?.elevationStats.min]

    z '.z-elevation-chart', {
      key: 'elevation-chart'
      onclick: (e) =>
        percent = (e.offsetX - padding) / (width - padding * 2)
        if percent >= 0 and percent <= 1
          # geodist isn't super accurate for long distances...
          # but we still use to get elevation
          rawDistance = percent * scale.rangeRange # memters
          dist = 0
          routePoints = MapService.decodePolyline mainRoute.shape
          # so we just go off of the percent complete through line
          # this still is somewhat inaccurate...
          # doesn't grab the exact right coordinates, just ballarpk
          roughDistance = _reduce routePoints, (sum, point, i) ->
            if routePoints[i - 1]
              sum += geodist routePoints[i - 1], point, {unit: 'meters', exact: true}
            sum
          , 0
          distance = percent * roughDistance
          point = _find routePoints, (point, i) ->
            if routePoints[i - 1]
              dist += geodist routePoints[i - 1], point, {unit: 'meters', exact: true}
            if dist > distance
              dist = 0
              return true
            return false
          elevation = _find(mainRoute.elevations, ([range, elevation]) ->
            rawDistance <= range)?[1]
          @routeFocus.next {
            icon: 'search'
            name: elevation or ''
            location:
              lat: point[1]
              lon: point[0]
          }
      # style:
        # width: "#{width}px"
        # height: "#{height}px"
    },
      if width
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
            "#{max} "
            @model.l.get 'editTripSettings.feetAbbr'

          z 'text', {
            namespace: 'http://www.w3.org/2000/svg'
            attributes:
              x: width - padding
              y: height - padding
              'text-anchor': 'end'
          },
            "#{min} "
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

          if altRoute
            z 'polyline', {
              namespace: 'http://www.w3.org/2000/svg'
              attributes:
                fill: 'none'
                stroke: colors.$grey500
                'stroke-width': 4
                'stroke-dasharray': '10,10'
                points: alternativePoints.join ' '
            }
