z = require 'zorium'
RxObservable = require('rxjs/Observable').Observable
require 'rxjs/add/observable/of'
_map = require 'lodash/map'

Icon = require '../icon'
Base = require '../base'
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
      products: item.switchMap (item) =>
        unless item.id
          return RxObservable.of []
        @model.product.getAllByItemId item.id
        .map (products) =>
          _map products, (product) =>
            $productBox = @getCached$(
              "product-#{product.id}", ProductBox, {@model, @router, product}
            )
            {$productBox}

  beforeUnmount: ->
    super()

  render: =>
    {item, products} = @state.getValue()

    z '.z-item',
      if item?.name
        z '.g-grid',
          z '.why',
            z '.subhead', @model.l.get 'item.why'
            item?.why
          z '.what',
            z '.subhead', @model.l.get 'item.what'
            item?.what
          z '.products',
            z '.subhead', @model.l.get 'general.products'
            z '.g-grid',
              z '.g-cols',
                _map products, ({$productBox}) ->
                  z '.g-col.g-xs-6.g-md-3',
                    z $productBox
      else
        z @$spinner
