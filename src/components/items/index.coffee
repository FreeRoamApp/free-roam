z = require 'zorium'
_map = require 'lodash/map'
_take = require 'lodash/take'
_snakeCase = require 'lodash/snakeCase'
RxObservable = require('rxjs/Observable').Observable
require 'rxjs/add/observable/of'

Icon = require '../icon'
Base = require '../base'
colors = require '../../colors'
config = require '../../config'

if window?
  require './index.styl'

MAX_PRODUCTS = 3

module.exports = class Items extends Base
  constructor: ({@model, @router, filter, filterInfo}) ->
    me = @model.user.getMe()

    @state = z.state
      filterInfo: filterInfo
      items: filter.switchMap (filter) =>
        items = if filter?.type is 'category'
          @model.item.getAllByCategory(filter.value)
        else if filter?.type is 'search'
          @model.item.search {
            query:
              multi_match:
                type: 'phrase_prefix'
                query: filter.value
                fields: ['name', 'what', 'why']
          }
        else
          RxObservable.of null

        items.map (items) ->
          _map items, (item) ->
            {
              item
              $chevronIcon: new Icon()
            }

  render: =>
    {filterInfo, items} = @state.getValue()

    snakeSlug = _snakeCase filterInfo?.slug

    z '.z-items',
      z '.g-grid.overflow-visible',
        if filterInfo?.slug
          z '.category-info',
            z '.icon',
              style:
                backgroundImage:
                  "url(#{config.CDN_URL}/guides/#{snakeSlug}.jpg)"
            z '.name', filterInfo?.name
            z '.description',
              filterInfo?.description
              .replace /{home}/g, 'RV'
              .replace /{Home}/g, 'RV'
        z '.g-cols',
          _map items, ({item, $chevronIcon}) =>
              visibleProducts = _take(item.productSlugs, MAX_PRODUCTS)
              productsRemaining = item.productSlugs.length -
                                    visibleProducts.length

              @router.link z 'a.item', {
                href: @router.get 'item', {
                  slug: item.slug
                }
              },
                z '.top',
                  z '.name',
                    item?.name
                z '.products',
                  _map visibleProducts, (slug, i) ->
                    hasMore = productsRemaining > 0 and
                                i is visibleProducts.length - 1
                    z '.image', {
                      className: z.classKebab {hasMore}
                      style:
                        backgroundImage:
                          "url(#{config.CDN_URL}/products/#{slug}-300h.jpg)"
                    },
                      if hasMore
                        z '.count', "+#{productsRemaining}"
                z '.bottom',
                  z '.text', @model.l.get 'items.seeProducts', {
                    replacements: count: item.productSlugs.length
                  }
                  z '.chevron',
                    z $chevronIcon,
                      icon: 'chevron-right'
                      color: colors.$primaryMain
                      isTouchTarget: false
