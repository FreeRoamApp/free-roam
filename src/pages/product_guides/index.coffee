z = require 'zorium'
_map = require 'lodash/map'

AppBar = require '../../components/app_bar'
ButtonMenu = require '../../components/button_menu'
ProductGuides = require '../../components/product_guides'
colors = require '../../colors'
config = require '../../config'

if window?
  require './index.styl'

module.exports = class ProductGuidesPage
  # hideDrawer: true
  @hasBottomBar: true

  constructor: ({@model, @router, requests, serverData, group, @$bottomBar}) ->
    @$appBar = new AppBar {@model}
    @$buttonMenu = new ButtonMenu {@model, @router}
    @$productGuides = new ProductGuides {@model, @router}

  getMeta: =>
    {
      title: @model.l.get 'productGuidesPage.metaTitle'
      description: @model.l.get 'productGuidesPage.description'
    }

  render: =>
    z '.p-product-guides',
      z @$appBar, {
        title: @model.l.get 'productGuidesPage.title'
        style: 'primary'
        $topLeftButton: z @$buttonMenu, {color: colors.$header500Icon}
      }
      @$productGuides
      @$bottomBar
