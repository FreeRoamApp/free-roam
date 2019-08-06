z = require 'zorium'
_defaults = require 'lodash/defaults'
_map = require 'lodash/map'
_filter = require 'lodash/filter'
_snakeCase = require 'lodash/snakeCase'

Base = require '../base'
TripCard = require '../trip_card'
colors = require '../../colors'
config = require '../../config'

if window?
  require './index.styl'

module.exports = class TripList extends Base
  constructor: ({@model, @router, trips, cachePrefix = 'mine'}) ->
    me = @model.user.getMe()

    @state = z.state
      me: me
      $trips: trips.map (trips) =>
        _map trips, (trip) =>
          cacheId = "tripCard-#{cachePrefix}-#{trip.id}"
          @getCached$ cacheId, TripCard, {
            @model, @router, trip
          }


  render: =>
    {me, $trips} = @state.getValue()

    z '.z-trip-list',
      _map $trips, ($trip) ->
        z '.trip', $trip
