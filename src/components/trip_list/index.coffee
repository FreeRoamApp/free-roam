z = require 'zorium'
RxObservable = require('rxjs/Observable').Observable
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
  constructor: (options) ->
    {@model, @router, trips, cachePrefix, @selectedTripIdStreams} = options
    cachePrefix ?= 'mine'

    me = @model.user.getMe()

    @$spinner = new Spinner()

    @state = z.state
      me: me
      selectedTripId: @selectedTripIdStreams?.switch()
      $trips: trips.map (trips) =>
        if _isEmpty trips
          return false
        _map trips, (trip) =>
          cacheId = "tripListItem-#{cachePrefix}-#{trip.id}-#{trip.type}"
          {
            trip: trip
            $trip: @getCached$ cacheId, TripListItem, {
              @model, @router, trip
            }
          }


  render: ({emptyIcon, emptyTitle, emptyDescription}) =>
    {me, selectedTripId, $trips} = @state.getValue()

    emptyIcon ?= 'trip_following_empty'
    emptyTitle ?= @model.l.get 'tripsMine.emptyTitle'
    emptyDescription ?= @model.l.get 'tripsMine.emptyDescription'

    z '.z-trip-list',
      if not $trips?
        @$spinner
      else if $trips is false
        z '.placeholder',
          z '.icon'
          z '.title', emptyTitle
          z '.description', emptyDescription
      else
        z '.g-grid',
          z '.g-cols',
            _map $trips, ({$trip, trip}) =>
              z '.g-col.g-xs-12.g-md-6',
                z '.trip',
                  z $trip, {
                    isSelected: selectedTripId and selectedTripId is trip.id
                    onclick: if @selectedTripIdStreams
                      (trip) =>
                        @selectedTripIdStreams.next RxObservable.of trip.id
                  }
