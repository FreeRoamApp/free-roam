z = require 'zorium'
RxObservable = require('rxjs/Observable').Observable
require 'rxjs/add/observable/of'
_map = require 'lodash/map'
_isEmpty = require 'lodash/isEmpty'

Icon = require '../icon'
SecondaryButton = require '../secondary_button'
Spinner = require '../spinner'
Environment = require '../../services/environment'
colors = require '../../colors'
config = require '../../config'

if window?
  require './index.styl'

module.exports = class ItemProducts
  constructor: ({@model, @router, item}) ->
    me = @model.user.getMe()
    @$spinner = new Spinner()

    @state = z.state
      item: item
      partner: @model.user.getPartner()
      products: item.switchMap (item) =>
        unless item?.slug
          return RxObservable.of []
        @model.product.getAllByItemSlug item.slug
        .map (products) ->
          _map products, (product) ->
            {
              product
              $buyButton: new SecondaryButton()
              $videoIcon: new Icon()
              # $saveIcon: new Icon()
            }

  openAmazon: ({partner, product, item}) =>
    ga? 'send', 'event', 'amazon', item?.slug, product.slug
    affiliateCode = partner?.amazonAffiliateCode or 'freeroamfound-20'

    # TODO: rm when ad grants disabled
    isNativeApp = Environment.isNativeApp 'freeroam'
    if affiliateCode is 'freeroamfound-20' and not isNativeApp
      affiliateCode = null

    @model.portal.call 'browser.openWindow', {
      url: if affiliateCode \
           then "https://amazon.com/dp/#{product.sourceId}?tag=#{affiliateCode}"
           else "https://amazon.com/dp/#{product.sourceId}"
      target: '_system'
    }

  render: =>
    {item, products, partner} = @state.getValue()

    z '.z-item-products',
      if item?.name
        z '.g-grid.overflow-visible',
          z '.g-cols.lt-md-no-padding',
            _map products, ({product, $buyButton, $videoIcon}) =>
              z '.g-col.g-xs-12.g-md-6',
                z '.product', {
                  onclick: => @openAmazon {partner, product, item}
                },
                  z '.content',
                    z '.image',
                      style:
                        backgroundImage: "url(#{config.CDN_URL}/products/#{product?.slug}-300h.jpg)"
                    z '.buy',
                      z $buyButton, {
                        text: @model.l.get 'product.buyAmazon'
                        onclick: => @openAmazon {partner, product}
                      }
                    z '.name',
                      product?.name
                    z '.description', product?.description
                    # z '.pros-cons',
                    #   z '.pros',
                    #     z '.title', @model.l.get 'product.pros'
                    #     _map product?.reviewersLiked, (like) ->
                    #       z '.pro', like
                    #   z '.cons',
                    #     z '.title', @model.l.get 'product.cons'
                    #     _map product?.reviewersDisliked, (dislike) ->
                    #       z '.con', dislike
                    z '.decisions',
                      _map product?.decisions, (decision) ->
                        z '.decision', decision
                  if product?.videos?[0]
                    z '.bottom',
                      z '.left', {
                        onclick: (e) =>
                          e.stopPropagation()
                          sourceId = product?.videos?[0]?.sourceId
                          @model.portal.call 'browser.openWindow', {
                            url:
                              "https://youtube.com/watch?v=#{sourceId}"
                          }
                      },
                        z '.icon',
                          z $videoIcon,
                            icon: 'youtube'
                            color: colors.$black54
                            isTouchTarget: false
                        z '.text', @model.l.get 'product.watchVideo'


      else
        z @$spinner
