z = require 'zorium'
_map = require 'lodash/map'
_snakeCase = require 'lodash/snakeCase'
RxBehaviorSubject = require('rxjs/BehaviorSubject').BehaviorSubject

Icon = require '../icon'
SearchInput = require '../search_input'
Spinner = require '../spinner'
UiCard = require '../ui_card'
Environment = require '../../services/environment'
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
      categories: @model.category.getAll().map (categories) ->
        _map categories, (category) ->
          {
            category
            $chevronIcon: new Icon()
          }
      hasSeenProductGuidesCard: @model.cookie.get 'hasSeenProductGuidesCard'

  render: =>
    {categories, hasSeenProductGuidesCard} = @state.getValue()

    z '.z-product-guides',
      z '.g-grid.overflow-visible',
        unless hasSeenProductGuidesCard
          z '.info-card',
            z @$infoCard, {
              $title: @model.l.get 'productGuides.infoCardTitle'
              $content:
                if Environment.isNativeApp('freeroam')
                  @model.l.get 'productGuides.infoCardNative'
                else
                  @model.l.get 'productGuides.infoCard'
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
            _map categories, ({category, $chevronIcon}, i) =>
              products = category.itemNames.join ', '
              snakeSlug = _snakeCase category.slug
              z '.g-col.g-xs-12.g-md-6',
                @router.link z 'a.card', {
                  href: @router.get 'itemsByCategory', {category: category.slug}
                },
                  z '.top',
                    z '.icon',
                      style:
                        backgroundImage:
                          "url(#{config.CDN_URL}/guides/#{snakeSlug}.jpg)"
                    z '.content',
                      z '.name', category.name
                      z '.products', "#{products}..."
                    z '.chevron',
                      z $chevronIcon,
                        icon: 'chevron-right'
                        color: colors.$primaryMain
                        isTouchTarget: false
                  z '.description',
                    category.description.replace /{home}/g, 'RV'
          else
            @$spinner
