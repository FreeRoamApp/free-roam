z = require 'zorium'
_map = require 'lodash/map'
_maxBy = require 'lodash/maxBy'
_minBy = require 'lodash/minBy'
RxObservable = require('rxjs/Observable').Observable
require 'rxjs/add/observable/of'

colors = require '../../colors'

if window?
  require './index.styl'

module.exports = class ElevationChart
  constructor: ({routes, size}) ->
    size ?= RxObservable.of {width: 320}

    @state = z.state {
      routes
      size: size.map (size) ->
        console.log 'size', size
        size.width ?= 320
        size.height ?= size.width * 0.3
        size.padding ?= size.width * 0.02
        size
    }

  getPoints: (route) =>
    {size} = @state.getValue()
    {width, height, padding} = size or {}

    console.log width, height, padding

    elevations = route?.elevations
    minRange = _minBy(elevations, ([range, elevation]) -> range)?[0]
    maxRange = _maxBy(elevations, ([range, elevation]) -> range)?[0]

    minElevation = _minBy(elevations, ([range, elevation]) -> elevation)?[1]
    maxElevation = _maxBy(elevations, ([range, elevation]) -> elevation)?[1]

    _map elevations, ([range, elevation], i) =>
      [
        width - (padding + (range / maxRange) * (width - padding * 2))
        padding + (elevation / maxElevation) * (height - padding * 2)
      ]

  render: ({heightRatio}) =>
    {routes, size} = @state.getValue()

    {width, height, padding} = size or {}

    points = @getPoints routes?[0]
    alternativePoints = @getPoints routes?[1]

    z '.z-elevation-chart', {
      key: 'elevation-chart'
      style:
        width: "#{width}px"
        height: "#{height}px"
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
