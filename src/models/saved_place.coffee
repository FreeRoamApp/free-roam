config = require '../config'

module.exports = class SavedPlace
  namespace: 'savedPlaces'

  constructor: ({@auth}) -> null

  search: ({query, sort, limit}) =>
    @auth.stream "#{@namespace}.search", {query, sort, limit}

  getAll: ({includeDetails} = {}) =>
    @auth.stream "#{@namespace}.getAll", {includeDetails}

  upsert: (options) =>
    @auth.call "#{@namespace}.upsert", options, {invalidateAll: true}

  deleteByRow: (row) =>
    @auth.call "#{@namespace}.deleteByRow", {row}, {invalidateAll: true}
