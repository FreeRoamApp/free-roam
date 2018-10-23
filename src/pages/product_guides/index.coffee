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

    @state = z.state
      me: @model.user.getMe()
      windowSize: @model.window.getSize()

  getMeta: ->
    {
      title: @model.l.get 'productGuidesPage.metaTitle'
      description: @model.l.get 'productGuidesPage.description'
    }

  render: =>
    {me, windowSize} = @state.getValue()

    z '.p-product-guides', {
      style:
        height: "#{windowSize.height}px"
    },
      z @$appBar, {
        title: @model.l.get 'productGuidesPage.title'
        style: 'primary'
        $topLeftButton: z @$buttonMenu, {color: colors.$header500Icon}
      }
      @$productGuides
      @$bottomBar
