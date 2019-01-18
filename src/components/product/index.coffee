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
      partner: @model.user.getPartner()
      $description: new FormattedText {
        text: product.map (product) -> product.description
      }

  render: =>
    {product, partner, $description} = @state.getValue()

    z '.z-product',
      z '.g-grid',
        z '.box',
          z '.image',
            style:
              backgroundImage:
                "url(#{config.CDN_URL}/products/#{product?.slug}-200h.jpg)"
          z '.actions',
            z '.action',
              z @$buyButton, {
                text: @model.l.get 'product.buyAmazon'
                onclick: =>
                  ga? 'send', 'event', 'amazon', partner?.amazonAffiliateCode, product.slug
                  affiliateCode = partner?.amazonAffiliateCode or ''

                  @model.portal.call 'browser.openWindow', {
                    url: if affiliateCode and affiliateCode isnt 'freeroam02-20' \
                         then "https://amazon.com/dp/#{product.sourceId}?tag=#{affiliateCode}"
                         else "https://amazon.com/dp/#{product.sourceId}"
                    target: '_system'
                  }
              }
              # z '.action',
              #   z @$packButton, {
              #     text: @model.l.get 'product.addToPack'
              #     onclick: ->
              #       alert 'Coming soon!'
              #   }

        z '.content',
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
