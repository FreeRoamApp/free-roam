config = require '../config'

module.exports = class Trip
  namespace: 'trips'

  constructor: ({@auth, @proxy}) -> null

  getById: (id) =>
    @auth.stream "#{@namespace}.getById", {id}

  getByType: (type) =>
    @auth.stream "#{@namespace}.getByType", {type}

  getRoute: ({checkIns}) =>
    @auth.stream "#{@namespace}.getRoute", {checkIns}, {ignoreCache: true}

  getStats: ({checkIns}) =>
    @auth.stream "#{@namespace}.getStats", {checkIns}, {ignoreCache: true}

  getStatesGeoJson: =>
    @auth.stream "#{@namespace}.getStatesGeoJson", {ignoreCache: true}

  addCheckIn: (options) =>
    @auth.call "#{@namespace}.addCheckIn", options, {
      invalidateAll: true
    }

  upsert: (options) =>
    @auth.call "#{@namespace}.upsert", options, {
      invalidateAll: true
    }

  uploadImage: (blob) =>
    formData = new FormData()
    formData.append 'file', blob

    @proxy config.API_URL + '/upload', {
      method: 'post'
      query:
        path: "#{@namespace}.uploadImage"
      body: formData
    }
    # .then (response) =>
    #   @exoid.invalidateAll()
    #   response
