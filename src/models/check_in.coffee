config = require '../config'

module.exports = class CheckIn
  namespace: 'checkIns'

  constructor: ({@auth, @proxy}) -> null

  getById: (id) =>
    @auth.stream "#{@namespace}.getById", {id}

  getAll: ({includeDetails} = {}) =>
    @auth.stream "#{@namespace}.getAll", {includeDetails}

  upsert: (options) =>
    @auth.call "#{@namespace}.upsert", options, {invalidateAll: true}
    .then (response) ->
      # TODO: figure out way to listen to stream

      response

  deleteByRow: (row) =>
    @auth.call "#{@namespace}.deleteByRow", {row}, {invalidateAll: true}

  uploadImage: (blob) =>
    formData = new FormData()
    formData.append 'file', blob

    @proxy config.API_URL + '/upload', {
      method: 'post'
      query:
        path: "#{@namespace}.uploadImage"
      body: formData
    }
