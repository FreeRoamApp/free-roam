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

  deleteByRow: (row) =>
    @auth.call "#{@namespace}.deleteByRow", {row}, {
      invalidateAll: true
    }
