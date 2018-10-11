z = require 'zorium'

AppBar = require '../../components/app_bar'
ButtonBack = require '../../components/button_back'
Product = require '../../components/product'
config = require '../../config'
colors = require '../../colors'

if window?
  require './index.styl'

module.exports = class ProductPage
  hideDrawer: true

  constructor: ({@model, @router, requests, serverData, group}) ->
    @product = requests.switchMap ({route}) =>
      @model.product.getBySlug route.params.slug

    @$appBar = new AppBar {@model}
    @$buttonBack = new ButtonBack {@model, @router}
    @$product = new Product {@model, @router, @product}

    @state = z.state
      me: @model.user.getMe()
      product: @product
      windowSize: @model.window.getSize()

  getMeta: ->
    @product.map (product) ->
      {
        title: product?.name
      }

  render: =>
    {me, product, windowSize} = @state.getValue()

    z '.p-product', {
      style:
        height: "#{windowSize.height}px"
    },
      z @$appBar, {
        title: product?.item?.name
        style: 'primary'
        $topLeftButton: z @$buttonBack, {color: colors.$header500Icon}
      }
      @$product
