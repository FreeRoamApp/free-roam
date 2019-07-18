z = require 'zorium'
_defaults = require 'lodash/defaults'
_map = require 'lodash/map'
_filter = require 'lodash/filter'
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
        now = new Date()
        _filter _map events, (event) ->
          endTime = new Date(event.endTime)
          if event.endTime and endTime < now
            return
          _defaults {
            startTime: DateService.format new Date(event.startTime), 'MMM D'
            endTime: DateService.format endTime, 'MMM D'
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
            if event?.name
              z '.content',
                z '.name', event.name
                z '.info',
                  "#{event.startTime} - #{event.endTime} · "
                  @model.placeBase.getLocation event
