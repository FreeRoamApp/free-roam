config = require '../config'

module.exports = class Category
  namespace: 'categories'

  constructor: ({@auth}) -> null

  getBySlug: (slug) =>
    @auth.stream "#{@namespace}.getBySlug", {slug}

  getAll: =>
    @auth.stream "#{@namespace}.getAll", {}
