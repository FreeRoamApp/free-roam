z = require 'zorium'

TravelMap = require '../../components/travel_map'
config = require '../../config'
colors = require '../../colors'

if window?
  require './index.styl'

# FIXME: screenshotter should have access to any trip (not just own trips)

module.exports = class TripMapScreenshot
  isPlain: true

  constructor: ({@model, @router, requests, serverData, group}) ->
    @trip = requests.switchMap ({route}) =>
      @model.trip.getById route.params.id

    @$travelMap = new TravelMap {
      @model, @router, @trip, prepScreenshot: true
    }

  getMeta: -> null

  render: =>
    z '.p-trip',
      @$travelMap
