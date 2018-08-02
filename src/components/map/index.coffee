z = require 'zorium'
_map = require 'lodash/map'

Icon = require '../icon'
Base = require '../base'
ProductBox = require '../product_box'
PrimaryButton = require '../primary_button'
colors = require '../../colors'
config = require '../../config'

if window?
  require './index.styl'

module.exports = class Item extends Base
  constructor: ({@model, @router, item}) ->
    @state = z.state {}

  render: =>
    {item, products} = @state.getValue()

    console.log 'item', item, products

    z '.z-item',
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
