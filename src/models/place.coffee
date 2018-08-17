config = require '../config'

module.exports = class Place
  namespace: 'places'

  constructor: ({@auth}) -> null

  getBySlug: (slug) =>
    @auth.stream "#{@namespace}.getBySlug", {slug}

  search: ({query}) =>
    @auth.stream "#{@namespace}.search", {query}
