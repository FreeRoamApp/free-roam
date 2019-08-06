z = require 'zorium'
_defaults = require 'lodash/defaults'
_snakeCase = require 'lodash/snakeCase'

Icon = require '../icon'
DateService = require '../../services/date'
colors = require '../../colors'
config = require '../../config'

if window?
  require './index.styl'

module.exports = class TripCard
  constructor: ({@model, @router, trip}) ->
    me = @model.user.getMe()

    now = new Date()
    console.log 'TRIP', trip
    # firstDate = _minBy
    startTime = new Date(trip.overview.startTime)
    endTime = new Date(trip.overview.endTime)
    @trip = _defaults {
      isPast: endTime < now
      startTime: DateService.format startTime, 'MMM D'
      endTime: DateService.format endTime, 'MMM D'
    }, trip

    @state = z.state
      me: me

  render: =>
    {me} = @state.getValue()

    trip = @trip

    @router.link z 'a.z-trip-card', {
      href: @router.get 'trip', {id: trip?.id}
    },
      z '.g-grid',
        z '.image',
          style:
            backgroundImage:
              "url(#{config.CDN_URL}/trips/_thumbnail.jpg)"
        if trip?.name
          z '.content',
            z '.name', trip.name
            z '.dates',
              "#{trip.startTime} - #{trip.endTime} · "
              @model.placeBase.getLocation trip
            z '.stats',
              @model.l.get 'tripCard.stats', {
                replacements:
                  distance: Math.round trip?.overview?.distance
                  stops: trip?.overview?.stops
              }
