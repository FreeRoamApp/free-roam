z = require 'zorium'
_map = require 'lodash/map'
RxBehaviorSubject = require('rxjs/BehaviorSubject').BehaviorSubject


Icon = require '../icon'
SearchInput = require '../search_input'
colors = require '../../colors'
config = require '../../config'

if window?
  require './index.styl'

BG_COLORS = [
  colors.$blue50026
  colors.$green50026
  colors.$red50026
]

module.exports = class Categories
  constructor: ({@model, @router, categories}) ->
    me = @model.user.getMe()

    @searchValue = new RxBehaviorSubject null
    @$searchInput = new SearchInput {@model, @router, @searchValue}

    @state = z.state
      categories: @model.category.getAll()

  render: =>
    {categories} = @state.getValue()

    z '.z-categories',
      z '.g-grid',
        z '.search',
          z @$searchInput, {
            isSearchIconRight: true
            placeholder: @model.l.get 'categories.searchPlaceholder'
            onsubmit: =>
              @router.go 'itemsBySearch', {query: @searchValue.getValue()}
          }
        z '.g-cols',
          _map categories, (category, i) =>
            productId = category?.data?.defaultProductId or
                          category?.firstItemFirstProductId
            z '.g-col.g-xs-12.g-md-6',
              @router.link z 'a.category', {
                href: @router.get 'itemsByCategory', {category: category.id}
              },
                z '.background',
                  style:
                    backgroundImage:
                      "url(#{config.CDN_URL}/products/#{productId}-200h.jpg)"
                  z '.gradient'
                z '.overlay', {
                  style:
                      backgroundColor: BG_COLORS[i % BG_COLORS.length]
                },
                  z '.name', category.name
                  z '.description', category.description
