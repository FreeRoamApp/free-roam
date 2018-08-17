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
        canonical: "https://#{config.HOST}"
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
        $topRightButton:
          z '.p-group-home_top-right',
            z @$notificationsIcon,
              icon: 'notifications'
              color: colors.$header500Icon
              onclick: =>
                @overlay$.next @$notificationsOverlay
            z @$settingsIcon,
              icon: 'settings'
              color: colors.$header500Icon
              onclick: =>
                @overlay$.next new SetLanguageDialog {
                  @model, @router, @overlay$, @group
                }
      }
      @$product
