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
        slug: product.slug
      }
    },
      z '.image',
        style:
          backgroundImage: "url(#{config.CDN_URL}/products/#{product?.slug}-200h.jpg)"
      z '.name',
        product?.name
