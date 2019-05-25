z = require 'zorium'
RxObservable = require('rxjs/Observable').Observable
require 'rxjs/add/observable/of'

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
      if route.params.id
        @model.trip.getById route.params.id
      else
        RxObservable.of null

    @$travelMap = new TravelMap {
      @model, @router, @trip, prepScreenshot: true
    }

  getMeta: -> null

  render: =>
    z '.p-trip',
      @$travelMap
