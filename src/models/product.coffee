config = require '../config'

module.exports = class Product
  namespace: 'products'

  constructor: ({@auth}) -> null

  getById: (id) =>
    @auth.stream "#{@namespace}.getById", {id}

  getAllByItemId: (itemId) =>
    @auth.stream "#{@namespace}.getAllByItemId", {itemId}
