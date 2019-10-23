z = require 'zorium'

TripList = require '../trip_list'

if window?
  require './index.styl'

module.exports = class TripsFollowing
  constructor: ({@model, @router}) ->
    trips = @model.user.getMe().switchMap (me) =>
      @model.trip.getAllFollowingByUserId me.id

    @$tripList = new TripList {@model, @router, trips, cachePrefix: 'follow'}

    # @state = z.state {}

  render: =>
    # {} = @state.getValue()

    z '.z-trips-following',
      z @$tripList,
        emptyIcon: 'trip_following_empty'
        emptyTitle: @model.l.get 'tripsFollowing.emptyTitle'
        emptyDescription: @model.l.get 'tripsFollowing.emptyDescription'
