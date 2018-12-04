z = require 'zorium'
RxObservable = require('rxjs/Observable').Observable
require 'rxjs/add/observable/of'
_map = require 'lodash/map'
_isEmpty = require 'lodash/isEmpty'

Spinner = require '../spinner'
colors = require '../../colors'
config = require '../../config'

if window?
  require './index.styl'

module.exports = class ItemProducts
  constructor: ({@model, @router, item}) ->
    me = @model.user.getMe()
    @$spinner = new Spinner()

    @state = z.state
      item: item
      products: item.switchMap (item) =>
        unless item?.slug
          return RxObservable.of []
        @model.product.getAllByItemSlug item.slug

  render: =>
    {item, products} = @state.getValue()

    z '.z-item-products',
      if item?.name
        z '.g-grid',
          z '.g-cols.lt-md-no-padding',
            _map products, (product) =>
              z '.g-col.g-xs-12.g-md-6',
                @router.link z 'a.product', {
                  href: @router.get 'product', {
                    slug: product.slug
                  }
                },
                  z '.image',
                    style:
                      backgroundImage: "url(#{config.CDN_URL}/products/#{product?.slug}-200h.jpg)"
                  z '.name',
                    product?.name

      else
        z @$spinner
