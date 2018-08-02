config = require '../config'

module.exports = class Item
  namespace: 'items'

  constructor: ({@auth}) -> null

  getById: (id) =>
    @auth.stream "#{@namespace}.getById", {id}

  getAll: =>
    @auth.stream "#{@namespace}.getAll", {}
