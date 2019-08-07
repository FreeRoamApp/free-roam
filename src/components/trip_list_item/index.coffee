z = require 'zorium'
_defaults = require 'lodash/defaults'
_snakeCase = require 'lodash/snakeCase'

Icon = require '../icon'
DateService = require '../../services/date'
FormatService = require '../../services/format'
colors = require '../../colors'
config = require '../../config'

if window?
  require './index.styl'

module.exports = class TripListItem
  constructor: ({@model, @router, trip}) ->
    me = @model.user.getMe()

    now = new Date()
    # firstDate = _minBy
    startTime = new Date(trip.overview.startTime)
    endTime = new Date(trip.overview.endTime)
    @trip = _defaults {
      isPast: endTime < now
      startTime: if trip.overview.startTime
        DateService.format startTime, 'MMM D'
      endTime: if trip.overview.endTime
        DateService.format endTime, 'MMM D'
    }, trip

    @state = z.state
      me: me

  render: =>
    {me} = @state.getValue()

    trip = @trip

    if trip.thumbnailPrefix
      imageUrl = @model.image.getSrcByPrefix(trip?.thumbnailPrefix)
    else if trip
      imageUrl = "#{config.CDN_URL}/trips/empty_trip.svg"
    else
      imageUrl = null

    @router.link z 'a.z-trip-list-item', {
      href:
        if trip?.id
          @router.get 'trip', {id: trip?.id}
        else
          @router.get 'tripByType', {type: trip?.type}
    },
      z '.g-grid',
        z '.image',
          style:
            backgroundImage: if imageUrl
              "url(#{imageUrl})"
        if trip?.name
          z '.content',
            z '.name', trip.name
            z '.dates',
              if trip.endTime
                "#{trip.startTime} - #{trip.endTime}"
              else if trip.startTime
                "#{trip.startTime}"
            z '.stats',
              @model.l.get 'tripCard.stats', {
                replacements:
                  distance: FormatService.number trip?.overview?.distance or 0
                  stops: trip?.overview?.stops
              }
