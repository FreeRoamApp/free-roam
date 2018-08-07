config = require '../config'

module.exports = class Category
  namespace: 'categories'

  constructor: ({@auth}) -> null

  getById: (id) =>
    @auth.stream "#{@namespace}.getById", {id}

  getAll: =>
    @auth.stream "#{@namespace}.getAll", {}
