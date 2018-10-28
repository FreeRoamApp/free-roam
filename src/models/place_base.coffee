config = require '../config'

module.exports = class PlaceBase
  constructor: ({@auth}) -> null

  getBySlug: (slug) =>
    @auth.stream "#{@namespace}.getBySlug", {slug}

  search: ({query}) =>
    @auth.stream "#{@namespace}.search", {query}

  upsert: (options) =>
    @auth.call "#{@namespace}.upsert", options, {invalidateAll: true}

  deleteByRow: (row) =>
    @auth.call "#{@namespace}.deleteByRow", {row}, {invalidateAll: true}

  getAmenityBoundsById: (id) =>
    @auth.stream "#{@namespace}.getAmenityBoundsById", {id}
