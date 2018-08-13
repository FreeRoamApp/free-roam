z = require 'zorium'
_map = require 'lodash/map'
RxObservable = require('rxjs/Observable').Observable
require 'rxjs/add/observable/of'

Icon = require '../icon'
Base = require '../base'
ItemBox = require '../item_box'
colors = require '../../colors'
config = require '../../config'

if window?
  require './index.styl'

module.exports = class Items extends Base
  constructor: ({@model, @router, filter}) ->
    me = @model.user.getMe()

    @state = z.state
      items: filter.switchMap (filter) =>
        console.log 'filter', filter
        items = if filter.type is 'category'
          @model.item.getAllByCategory(filter.value)
        else if filter.type is 'search'
          @model.item.search {
            query:
              multi_match:
                query: filter.value
                fields: ['name', 'what', 'why']
          }
        else
          RxObservable.of null
        items.map (items) =>
          _map items, (item) =>
            $itemBox = @getCached$(
              "item-#{item.id}", ItemBox, {@model, @router, item}
            )
            {$itemBox}

  beforeUnmount: ->
    super()

  render: =>
    {items} = @state.getValue()

    z '.z-items',
      z '.g-grid',
        z '.g-cols',
          _map items, ({$itemBox}) ->
            z '.g-col.g-xs-6.g-md-3', $itemBox
