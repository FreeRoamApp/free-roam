z = require 'zorium'

TravelMap = require '../travel_map'
colors = require '../../colors'
config = require '../../config'

if window?
  require './index.styl'

module.exports = class TripMap
  constructor: ({@model, @router, @trip, destinations}) ->
    @$travelMap = new TravelMap {
      @model, @router, @trip, destinations
    }

    @state = z.state {
      @trip
      destinations
    }

  share: =>
    @$travelMap.share()

  render: =>
    {trip, destinations} = @state.getValue()

    z '.z-trip-map', {
      ontouchstart: (e) -> e.stopPropagation()
      onmousedown: (e) -> e.stopPropagation()
    },
      z @$travelMap
