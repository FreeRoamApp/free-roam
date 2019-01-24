module.exports = class Product
  namespace: 'products'

  constructor: ({@auth}) -> null

  getBySlug: (slug) =>
    @auth.stream "#{@namespace}.getBySlug", {slug}

  getAllByItemSlug: (itemSlug) =>
    @auth.stream "#{@namespace}.getAllByItemSlug", {itemSlug}
