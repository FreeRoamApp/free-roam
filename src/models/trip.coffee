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

  getStatesGeoJson: =>
    @auth.stream "#{@namespace}.getStatesGeoJson", {ignoreCache: true}

  hasEditPermission: (trip, user) ->
    trip?.userId and trip?.userId is user?.id

  deleteByRow: (options) =>
    @auth.call "#{@namespace}.deleteByRow", options, {
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
