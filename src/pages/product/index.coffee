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
      product: @product

  getMeta: =>
    @product.map (product) ->
      {
        title: product?.name
        description: product?.description
      }

  render: =>
    {product} = @state.getValue()

    z '.p-product',
      z @$appBar, {
        title: product?.item?.name
        style: 'primary'
        $topLeftButton: z @$buttonBack, {color: colors.$header500Icon}
      }
      @$product
