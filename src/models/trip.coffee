config = require '../config'

module.exports = class Trip
  namespace: 'trips'

  constructor: ({@auth, @proxy, @exoid}) -> null

  getById: (id) =>
    @auth.stream "#{@namespace}.getById", {id}

  getAll: (id) =>
    @auth.stream "#{@namespace}.getAll", {id}

  getAllFollowingByUserId: (userId) =>
    @auth.stream "#{@namespace}.getAllFollowingByUserId", {userId}

  getByType: (type) =>
    @auth.stream "#{@namespace}.getByType", {type}

  getByUserIdAndType: (userId, type) =>
    @auth.stream "#{@namespace}.getByUserIdAndType", {userId, type}, {isErrorable: true}

  getRoute: ({checkIns}) =>
    @auth.stream "#{@namespace}.getRoute", {checkIns}, {ignoreCache: true}

  getStats: ({checkIns}) =>
    @auth.stream "#{@namespace}.getStats", {checkIns}, {ignoreCache: true}

  getRouteStopsByTripIdAndRouteIds: (tripId, routeIds) =>
    @auth.stream "#{@namespace}.getRouteStopsByTripIdAndRouteIds", {
      tripId, routeIds
    }

  getRoutesByTripIdAndRouteId: (tripId, routeId) =>
    @auth.stream "#{@namespace}.getRoutesByTripIdAndRouteId", {
      tripId, routeId
    }

  getStatesGeoJson: =>
    @auth.stream "#{@namespace}.getStatesGeoJson", {ignoreCache: true}

  upsertStopByIdAndRouteId: (id, routeId, checkIn) ->
    @auth.call "#{@namespace}.upsertStopByIdAndRouteId", {
      id, routeId, checkIn
    }, {invalidateAll: true}

  upsertDestinationById: (id, checkIn) ->
    @auth.call "#{@namespace}.upsertDestinationById", {
      id, checkIn
    }, {invalidateAll: true}

  deleteStopByIdAndRouteId: (id, routeId) ->
    @auth.call "#{@namespace}.deleteStopByIdAndRouteId", {
      id, routeId
    }, {invalidateAll: true}

  hasEditPermission: (trip, user) ->
    trip?.userId and trip?.userId is user?.id

  deleteByRow: (row) =>
    @auth.call "#{@namespace}.deleteByRow", {row}, {
      invalidateAll: true
    }

  upsert: (options, {file} = {}) =>
    if file
      formData = new FormData()
      formData.append 'file', file, file.name

      @proxy config.API_URL + '/upload', {
        method: 'post'
        query:
          path: "#{@namespace}.upsert"
          body: JSON.stringify options
        body: formData
      }
      # this (exoid.update) doesn't actually work... it'd be nice
      # but it doesn't update existing streams
      # .then @exoid.update
      .then (response) =>
        setTimeout @exoid.invalidateAll, 0
        response
    else
      @auth.call "#{@namespace}.upsert", options, {invalidateAll: true}
