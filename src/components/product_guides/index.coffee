z = require 'zorium'
_map = require 'lodash/map'
RxBehaviorSubject = require('rxjs/BehaviorSubject').BehaviorSubject


Icon = require '../icon'
SearchInput = require '../search_input'
Spinner = require '../spinner'
UiCard = require '../ui_card'
colors = require '../../colors'
config = require '../../config'

if window?
  require './index.styl'

BG_COLORS = [
  colors.$blue50026
  colors.$green50026
  colors.$red50026
]

module.exports = class ProductGuides
  constructor: ({@model, @router}) ->
    me = @model.user.getMe()

    @searchValue = new RxBehaviorSubject ''
    @$searchInput = new SearchInput {@model, @router, @searchValue}

    @$infoCard = new UiCard()

    @$spinner = new Spinner()

    @state = z.state
      categories: @model.category.getAll()
      hasSeenProductGuidesCard: @model.cookie.get 'hasSeenProductGuidesCard'

  render: =>
    {categories, hasSeenProductGuidesCard} = @state.getValue()

    z '.z-product-guides',
      z '.g-grid',
        unless hasSeenProductGuidesCard
          z '.info-card',
            z @$infoCard, {
              $title: @model.l.get 'productGuides.infoCardTitle'
              $content: @model.l.get 'productGuides.infoCard'
              submit:
                text: @model.l.get 'general.gotIt'
                onclick: =>
                  @state.set hasSeenProductGuidesCard: true
                  @model.cookie.set 'hasSeenProductGuidesCard', '1'
            }

        z '.search',
          z @$searchInput, {
            isSearchOnSubmit: true
            placeholder: @model.l.get 'productGuides.searchPlaceholder'
            onsubmit: =>
              @router.go 'itemsBySearch', {query: @searchValue.getValue()}
          }

        z '.g-cols.lt-md-no-padding',
          if categories
            _map categories, (category, i) =>
              productSlug = category?.data?.defaultProductSlug or
                            category?.firstItemFirstProductSlug
              z '.g-col.g-xs-12.g-md-6',
                @router.link z 'a.category', {
                  href: @router.get 'itemsByCategory', {category: category.slug}
                },
                  z '.background',
                    style:
                      backgroundImage:
                        "url(#{config.CDN_URL}/products/#{productSlug}-200h.jpg)"
                    z '.gradient'
                  z '.overlay', {
                    style:
                        backgroundColor: BG_COLORS[i % BG_COLORS.length]
                  },
                    z '.name', "\##{category.name.toLowerCase()}"
                    z '.description', category.description
          else
            @$spinner
