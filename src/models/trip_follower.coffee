_find = require 'lodash/find'

module.exports = class TripFollower
  namespace: 'tripFollowers'

  constructor: ({@auth}) -> null

  getAllByTripId: (tripId) =>
    @auth.stream "#{@namespace}.getAllByTripId", {tripId}

  getAllByUserId: (userId) =>
    @auth.stream "#{@namespace}.getAllByUserId", {userId}

  upsertByTripId: (tripId) =>
    @auth.call "#{@namespace}.upsertByTripId", {tripId}, {
      invalidateAll: true
    }

  deleteByTripId: (tripId) =>
    @auth.call "#{@namespace}.deleteByTripId", {tripId}, {
      invalidateAll: true
    }

  isFollowingByUserIdAndTripId: (userId, tripId) =>
    @getAllByUserId userId
    .map (tripFollowers) ->
      _find(tripFollowers, {tripId}) or false
