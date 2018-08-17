config = require '../config'

module.exports = class Item
  namespace: 'items'

  constructor: ({@auth}) -> null

  getBySlug: (slug) =>
    @auth.stream "#{@namespace}.getBySlug", {slug}

  getAll: =>
    @auth.stream "#{@namespace}.getAll", {}

  getAllByCategory: (category) =>
    @auth.stream "#{@namespace}.getAllByCategory", {category}

  search: ({query}) =>
    @auth.stream "#{@namespace}.search", {query}
