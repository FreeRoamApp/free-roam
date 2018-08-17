z = require 'zorium'
RxObservable = require('rxjs/Observable').Observable
require 'rxjs/add/observable/of'
_map = require 'lodash/map'
_isEmpty = require 'lodash/isEmpty'

Icon = require '../icon'
Base = require '../base'
EmbeddedVideo = require '../embedded_video'
FormattedText = require '../formatted_text'
ProductBox = require '../product_box'
PrimaryButton = require '../primary_button'
Spinner = require '../spinner'
colors = require '../../colors'
config = require '../../config'

if window?
  require './index.styl'

module.exports = class Item extends Base
  constructor: ({@model, @router, item}) ->
    me = @model.user.getMe()

    @$buyButton = new PrimaryButton()
    @$spinner = new Spinner()

    @state = z.state
      item: item
      $why: new FormattedText {
        text: item.map (item) -> item.why
      }
      $what: new FormattedText {
        text: item.map (item) -> item.what
      }
      $videos: item.map (item) =>
        _map item.videos, (video) =>
          new EmbeddedVideo {@model, video}
      products: item.switchMap (item) =>
        unless item.slug
          return RxObservable.of []
        @model.product.getAllByItemSlug item.slug
        .map (products) =>
          _map products, (product) =>
            $productBox = @getCached$(
              "product-#{product.slug}", ProductBox, {@model, @router, product}
            )
            {$productBox}

  beforeUnmount: ->
    super()

  render: =>
    {item, products, $why, $what, $videos} = @state.getValue()

    console.log item

    z '.z-item',
      if item?.name
        z '.g-grid',
          z '.why',
            z '.subhead', @model.l.get 'item.why'
            $why
          z '.what',
            z '.subhead', @model.l.get 'item.what'
            $what
          z '.products',
            z '.subhead', @model.l.get 'general.products'
            z '.g-grid',
              z '.g-cols',
                _map products, ({$productBox}) ->
                  z '.g-col.g-xs-6.g-md-3',
                    z $productBox
          unless _isEmpty item.videos
            [
              z '.title', @model.l.get 'item.helpfulVideos'
              _map $videos, ($video) ->
                z $video
            ]
      else
        z @$spinner
