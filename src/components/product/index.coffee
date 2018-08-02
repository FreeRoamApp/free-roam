z = require 'zorium'

Icon = require '../icon'
PrimaryButton = require '../primary_button'
SecondaryButton = require '../secondary_button'
colors = require '../../colors'
config = require '../../config'

if window?
  require './index.styl'

module.exports = class Product
  constructor: ({@model, @router, product}) ->
    me = @model.user.getMe()

    @$buyButton = new PrimaryButton()
    @$packButton = new SecondaryButton()

    @state = z.state
      product: product

  render: =>
    {product} = @state.getValue()

    z '.z-product',
      z '.g-grid',
        z '.image',
          style:
            backgroundImage:
              "url(#{config.CDN_URL}/products/#{product?.id}-200h.jpg)"
        z '.actions',
          z '.g-grid',
            z '.g-cols.no-padding',
              z '.g-col.g-xs-12.g-md-6',
                z @$buyButton, {
                  text: @model.l.get 'product.buyAmazon'
                  onclick: =>
                    @model.portal.call 'browser.openWindow', {
                      url: "https://amazon.com/dp/#{product.sourceId}"
                      target: '_system'
                    }
                }
              z '..g-col.g-xs-12.g-md-6',
                z @$packButton, {
                  text: @model.l.get 'product.addToPack'
                }
        z '.name',
          product?.name
        z '.description',
          product?.description

        # TODO: comparison
