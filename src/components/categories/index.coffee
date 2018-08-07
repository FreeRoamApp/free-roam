z = require 'zorium'
_map = require 'lodash/map'

Icon = require '../icon'
colors = require '../../colors'
config = require '../../config'

if window?
  require './index.styl'

module.exports = class Categories
  constructor: ({@model, @router, categories}) ->
    me = @model.user.getMe()

    @state = z.state
      categories: @model.category.getAll()

  render: =>
    {categories} = @state.getValue()

    console.log categories

    z '.z-categories',
      z '.g-grid',
        z '.g-cols',
          _map categories, (category) =>
            productId = category?.data?.defaultProductId or
                          category?.firstItemFirstProductId
            z '.g-col.g-xs-12.g-md-6',
              @router.link z 'a.category', {
                href: @router.get 'itemsByCategory', {category: category.id}
                style:
                  backgroundImage:
                    "url(#{config.CDN_URL}/products/#{productId}-200h.jpg)"
              },
                z '.overlay',
                  z '.name', category.name
                  z '.description', category.description
