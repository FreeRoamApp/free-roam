z = require 'zorium'
_map = require 'lodash/map'

Icon = require '../icon'
Base = require '../base'
ItemBox = require '../item_box'
colors = require '../../colors'
config = require '../../config'

if window?
  require './index.styl'

module.exports = class Items extends Base
  constructor: ({@model, @router, category}) ->
    me = @model.user.getMe()

    @state = z.state
      items: category.switchMap (category) =>
        @model.item.getAllByCategory(category).map (items) =>
          _map items, (item) =>
            $itemBox = @getCached$(
              "item-#{item.id}", ItemBox, {@model, @router, item}
            )
            {$itemBox}

  beforeUnmount: ->
    super()

  render: =>
    {items} = @state.getValue()

    console.log items

    z '.z-items',
      z '.g-grid',
        z '.g-cols',
          _map items, ({$itemBox}) ->
            z '.g-col.g-xs-6.g-md-3', $itemBox
