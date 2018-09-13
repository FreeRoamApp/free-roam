config = require '../config'

module.exports = class PlaceBase
  constructor: ({@auth}) -> null

  getBySlug: (slug) =>
    @auth.stream "#{@namespace}.getBySlug", {slug}

  search: ({query}) =>
    @auth.stream "#{@namespace}.search", {query}
