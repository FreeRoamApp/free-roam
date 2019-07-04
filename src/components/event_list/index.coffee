z = require 'zorium'
_defaults = require 'lodash/defaults'
_map = require 'lodash/map'
_snakeCase = require 'lodash/snakeCase'

Icon = require '../icon'
DateService = require '../../services/date'
colors = require '../../colors'
config = require '../../config'

if window?
  require './index.styl'

module.exports = class EventList
  constructor: ({@model, @router, events}) ->
    me = @model.user.getMe()

    @state = z.state
      me: me
      events: events.map (events) ->
        _map events, (event) ->
          _defaults {
            startTime: DateService.format new Date(event.startTime), 'MMM D'
            endTime: DateService.format new Date(event.endTime), 'MMM D'
          }, event

  render: =>
    {me, events} = @state.getValue()

    z '.z-event-list',
      # TODO: All, going maybe tabs
      _map events, (event) =>
        @router.link z 'a.event', {
          href: @router.get 'event', {slug: event?.slug}
        },
          z '.g-grid',
            z '.image',
              style:
                backgroundImage:
                  "url(#{config.CDN_URL}/events/#{_snakeCase(event.slug)}_thumbnail.jpg)"
            z '.content',
              z '.name', event.name
              z '.info',
                "#{event.startTime} - #{event.endTime} · "
                @model.placeBase.getLocation event
