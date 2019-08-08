z = require 'zorium'
_defaults = require 'lodash/defaults'
_map = require 'lodash/map'
_filter = require 'lodash/filter'
_isEmpty = require 'lodash/isEmpty'
_snakeCase = require 'lodash/snakeCase'

Base = require '../base'
Spinner = require '../spinner'
TripListItem = require '../trip_list_item'
colors = require '../../colors'
config = require '../../config'

if window?
  require './index.styl'

module.exports = class TripList extends Base
  constructor: ({@model, @router, trips, cachePrefix = 'mine'}) ->
    me = @model.user.getMe()

    @$spinner = new Spinner()

    @state = z.state
      me: me
      $trips: trips.map (trips) =>
        if _isEmpty trips
          return false
        _map trips, (trip) =>
          cacheId = "tripListItem-#{cachePrefix}-#{trip.id}-#{trip.type}"
          @getCached$ cacheId, TripListItem, {
            @model, @router, trip
          }


  render: =>
    {me, $trips} = @state.getValue()

    z '.z-trip-list',
      z '.g-grid',
        z '.g-cols',
          if not $trips?
            @$spinner
          else
            _map $trips, ($trip) ->
              z '.g-col.g-xs-12.g-md-6',
                z '.trip', $trip
