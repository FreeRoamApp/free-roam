z = require 'zorium'

AppBar = require '../../components/app_bar'
ButtonBack = require '../../components/button_back'
ItemProducts = require '../../components/item_products'
ItemGuide = require '../../components/item_guide'
BasePage = require '../base'
Tabs = require '../../components/tabs'
colors = require '../../colors'
config = require '../../config'

if window?
  require './index.styl'

module.exports = class ItemPage extends BasePage
  hideDrawer: true

  constructor: ({@model, @router, requests, serverData, group}) ->
    @item = @clearOnUnmount requests.switchMap ({route}) =>
      @model.item.getBySlug route.params.slug

    @$appBar = new AppBar {@model}
    @$tabs = new Tabs {@model}
    @$buttonBack = new ButtonBack {@model, @router}
    @$itemProducts = new ItemProducts {@model, @router, @item}
    @$itemGuide = new ItemGuide {@model, @router, @item}

    @state = z.state
      item: @item

  getMeta: =>
    @item.map (item) =>
      {
        title: @model.l.get 'itemPage.title', {replacements: {name: item?.name}}
        description: item?.why
      }

  render: =>
    {item} = @state.getValue()

    z '.p-item',
      z @$appBar, {
        title: item?.name
        isFlat: true
        $topLeftButton: z @$buttonBack, {color: colors.$header500Icon}
      }
      z @$tabs,
        isBarFixed: false
        tabs: [
          {
            $menuText: @model.l.get 'itemsPage.products'
            $el: @$itemProducts
          }
          {
            $menuText: @model.l.get 'itemsPage.guide'
            $el: z @$itemGuide
          }
        ]
      @$item
