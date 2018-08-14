config = require '../config'

module.exports = class Place
  namespace: 'places'

  constructor: ({@auth}) -> null

  getById: (id) =>
    @auth.stream "#{@namespace}.getById", {id}

  search: ({query}) =>
    @auth.stream "#{@namespace}.search", {query}
