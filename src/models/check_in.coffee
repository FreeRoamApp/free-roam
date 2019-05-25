RxReplaySubject = require('rxjs/ReplaySubject').ReplaySubject
config = require '../config'

module.exports = class CheckIn
  namespace: 'checkIns'

  constructor: ({@auth, @proxy}) -> null

  getById: (id) =>
    @auth.stream "#{@namespace}.getById", {id}

  getAll: ({includeDetails} = {}) =>
    @auth.stream "#{@namespace}.getAll", {includeDetails}

  upsert: (options) =>
    additionalDataStream = new RxReplaySubject()

    @auth.call "#{@namespace}.upsert", options, {
      invalidateAll: true
      additionalDataStream: additionalDataStream # stream in results after promise finishes
    }
    .then (response) =>
      invalidateTripMap = (trip) =>
        @auth.exoid.invalidate 'trips.getByUserIdAndType', {
          userId: trip.userId, type: 'past'
        }

      additionalDataStream.switch().subscribe (response) ->
        @unsubscribe() #
        invalidateTripMap response.updatedTrip
      response

  deleteByRow: (row) =>
    @auth.call "#{@namespace}.deleteByRow", {row}, {invalidateAll: true}

  hasEditPermission: (checkIn, user) ->
    checkIn?.userId and checkIn?.userId is user?.id

  getName: (checkIn) ->
    checkIn?.name or checkIn?.place?.name or checkIn?.place?.address?.locality

  uploadImage: (blob) =>
    formData = new FormData()
    formData.append 'file', blob

    @proxy config.API_URL + '/upload', {
      method: 'post'
      query:
        path: "#{@namespace}.uploadImage"
      body: formData
    }
