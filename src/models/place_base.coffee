config = require '../config'

module.exports = class PlaceBase
  constructor: ({@auth}) -> null

  getBySlug: (slug) =>
    @auth.stream "#{@namespace}.getBySlug", {slug}

  search: ({query, sort, limit}) =>
    @auth.stream "#{@namespace}.search", {query, sort, limit}

  upsert: (options, {invalidateAll}) =>
    invalidateAll ?= true
    @auth.call "#{@namespace}.upsert", options, {invalidateAll}

  deleteByRow: (row) =>
    @auth.call "#{@namespace}.deleteByRow", {row}, {invalidateAll: true}

  getNearestAmenitiesById: (id) =>
    @auth.stream "#{@namespace}.getNearestAmenitiesById", {id}
