z = require 'zorium'
_map = require 'lodash/map'

Icon = require '../icon'
Spinner = require '../spinner'
colors = require '../../colors'
config = require '../../config'

if window?
  require './index.styl'

module.exports = class Trips
  constructor: ({@model, @router}) ->
    me = @model.user.getMe()

    @$spinner = new Spinner()

    @state = z.state
      trips: @model.trip.getAll()

  render: =>
    {trips} = @state.getValue()

    z '.z-trips',
      z '.g-grid',
        z '.g-cols.lt-md-no-padding',
          z '.g-col.g-xs-12.g-md-6',
            @router.link z 'a.trip', {
              href: @router.get 'editTripByType', {type: 'past'}
            },
              z '.name', @model.l.get 'trips.pastName'
              z '.description', @model.l.get 'trips.pastDescription'
          z '.g-col.g-xs-12.g-md-6',
            @router.link z 'a.trip', {
              href: @router.get 'editTripByType', {type: 'future'}
            },
              z '.name', @model.l.get 'trips.futureName'
              z '.description', @model.l.get 'trips.futureDescription'

          # if trips
          #   _map trips, (trip, i) =>
          #     z '.g-col.g-xs-12.g-md-6',
          #       @router.link z 'a.trip', {
          #         href: @router.get 'editTripByType', {type: trip.type}
          #       },
          #         z '.name', trip.name
          #         # z '.description', trip.description
          # else
          #   @$spinner
