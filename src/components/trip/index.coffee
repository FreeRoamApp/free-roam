z = require 'zorium'
_omit = require 'lodash/omit'

Fab = require '../fab'
Icon = require '../icon'
Tabs = require '../tabs'
TripItenerary = require '../trip_itenerary'
TripMap = require '../trip_map'

if window?
  require './index.styl'

module.exports = class Trip
  constructor: ({@model, @router, @trip}) ->
    @$fab = new Fab()

    checkIns = @trip.map (trip) ->
      trip?.checkIns

    @$tripMap = new TripMap {@model, @router, @trip, checkIns}
    @$tripItenerary = new TripItenerary {@model, @router, @trip, checkIns}
    @$tabs = new Tabs {@model}

    @state = z.state {
      me: @model.user.getMe()
      trip: @trip.map (trip) ->
        _omit trip, ['route']
    }

  share: =>
    ga? 'send', 'event', 'trip', 'share', 'click'
    @$tripMap.share()

  render: =>
    {me, trip} = @state.getValue()

    hasEditPermission = @model.trip.hasEditPermission trip, me

    z '.z-trip',
      z '.cover', {
        # style:
        #   backgroundImage:
        #     "url(#{@getCoverUrl(event)})"
      }
      z @$tabs,
        isBarFixed: false
        tabs: [
          {
            $menuText: @model.l.get 'trip.itenerary'
            $el: @$tripItenerary
          }
          {
            $menuText: @model.l.get 'trip.map'
            $el: z @$tripMap
          }
        ]

      if hasEditPermission
        z '.fab',
          z @$fab,
            isPrimary: true
            icon: 'add'
            onclick: =>
              @router.go 'newCheckIn', {
                tripType: trip.type
                tripId: trip.id
              }
