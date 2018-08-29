z = require 'zorium'
_map = require 'lodash/map'
_isEmpty = require 'lodash/isEmpty'

Icon = require '../icon'
PrimaryButton = require '../primary_button'
SecondaryButton = require '../secondary_button'
FormattedText = require '../formatted_text'
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
      $description: new FormattedText {
        text: product.map (product) -> product.description
      }

  render: =>
    {product, $description} = @state.getValue()

    z '.z-product',
      z '.g-grid',
        z '.image',
          style:
            backgroundImage:
              "url(#{config.CDN_URL}/products/#{product?.slug}-200h.jpg)"
        z '.actions',
          z '.g-grid',
            z '.g-cols.no-padding',
              z '.g-col.g-xs-12.g-md-6',
                z @$buyButton, {
                  text: @model.l.get 'product.buyAmazon'
                  onclick: =>
                    ga? 'send', 'event', 'amazon', 'freeroam-20', product.slug
                    @model.portal.call 'browser.openWindow', {
                      url: "https://amazon.com/dp/#{product.sourceId}?tag=freeroam-20"
                      target: '_system'
                    }
                }
              # z '..g-col.g-xs-12.g-md-6',
              #   z @$packButton, {
              #     text: @model.l.get 'product.addToPack'
              #     onclick: ->
              #       alert 'Coming soon!'
              #   }
        z '.name',
          product?.name
        z '.description',
          $description

        # TODO: comparison

        unless _isEmpty product?.reviewersLiked
          [
            z '.title', @model.l.get 'product.reviewersLiked'
            z 'ul.reviewers-liked',
              _map product?.reviewersLiked, (item) ->
                z 'li.item', item
          ]

        unless _isEmpty product?.reviewersDisliked
          [
            z '.title', @model.l.get 'product.reviewersDisliked'
            z 'ul.reviewers-disliked',
              _map product?.reviewersDisliked, (item) ->
                z 'li.item', item
          ]
