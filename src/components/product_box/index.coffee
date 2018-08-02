z = require 'zorium'
_map = require 'lodash/map'

Icon = require '../icon'
colors = require '../../colors'
config = require '../../config'

if window?
  require './index.styl'

module.exports = class Product
  constructor: ({@model, @router, product}) ->
    @state = z.state
      product: product

  render: =>
    {product} = @state.getValue()

    @router.link z 'a.z-product-box', {
      href: @router.get 'product', {
        nameKebab: product.nameKebab
        id: product.id
      }
    },
      z '.image',
        style:
          backgroundImage: "url(#{config.CDN_URL}/products/#{product?.id}-200h.jpg)"
      z '.name',
        product?.name
