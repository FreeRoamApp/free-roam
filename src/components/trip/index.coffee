z = require 'zorium'
RxObservable = require('rxjs/Observable').Observable
require 'rxjs/add/observable/combineLatest'
_omit = require 'lodash/omit'

Fab = require '../fab'
Icon = require '../icon'
SecondaryButton = require '../secondary_button'
Tabs = require '../tabs'
TripItenerary = require '../trip_itenerary'
TripMap = require '../trip_map'
FormatService = require '../../services/format'
config = require '../../config'

if window?
  require './index.styl'

module.exports = class Trip
  constructor: ({@model, @router, @trip}) ->
    @$fab = new Fab()

    checkIns = @trip.map (trip) ->
      trip?.checkIns

    me = @model.user.getMe()

    tripAndMe = RxObservable.combineLatest(
      @trip, me, (vals...) -> vals
    )

    @$tripMap = new TripMap {@model, @router, @trip, checkIns}
    @$tripItenerary = new TripItenerary {@model, @router, @trip, checkIns}
    @$tabs = new Tabs {@model}

    @$followButton = new SecondaryButton()

    @state = z.state {
      me: me
      isFollowLoading: false
      isFollowing: tripAndMe.switchMap ([trip, me]) =>
        @model.tripFollower.isFollowingByUserIdAndTripId(
          me.id, trip?.id
        )
      trip: @trip.map (trip) ->
        _omit trip, ['route']
    }

  share: =>
    ga? 'send', 'event', 'trip', 'share', 'click'
    @$tripMap.share()

  render: =>
    {me, trip, isFollowLoading, isFollowing} = @state.getValue()

    hasEditPermission = @model.trip.hasEditPermission trip, me

    if trip?.thumbnailPrefix
      imageUrl = @model.image.getSrcByPrefix(trip?.thumbnailPrefix)
    else if trip
      imageUrl = "#{config.CDN_URL}/trips/empty_trip.svg"
    else
      imageUrl = null

    z '.z-trip',
      z '.info',
        z '.content',
          z '.picture',
            style:
              backgroundImage:
                "url(#{imageUrl})"
          z '.name', trip?.name
          z '.stats',
            @model.l.get 'tripCard.stats', {
              replacements:
                stops: trip?.overview?.stops
                distance: FormatService.number trip?.overview?.distance or 0
            }
          unless hasEditPermission
            z '.follow',
              z @$followButton, {
                isOutline: true
                isFullWidth: false
                isShort: true
                heightPx: 28
                text:
                  if isFollowLoading
                  then @model.l.get 'general.loading'
                  else if isFollowing
                  then @model.l.get 'general.following'
                  else @model.l.get 'general.follow'
                onclick: =>
                  (if isFollowing
                    @model.tripFollower.deleteByTripId trip.id
                  else
                    @model.tripFollower.upsertByTripId trip.id
                  ).catch (err) ->
                    console.log err
                  .then =>
                    @state.set isLoading: false
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
