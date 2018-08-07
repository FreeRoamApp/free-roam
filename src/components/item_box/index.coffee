z = require 'zorium'
_map = require 'lodash/map'

Icon = require '../icon'
colors = require '../../colors'
config = require '../../config'

if window?
  require './index.styl'

module.exports = class ItemBox
  constructor: ({@model, @router, item}) ->
    @state = z.state
      item: item

  render: =>
    {item} = @state.getValue()

    @router.link z 'a.z-item-box', {
      href: @router.get 'item', {
        id: item.id
      }
    },
      z '.image',
        style:
          backgroundImage:
            "url(#{config.CDN_URL}/products/#{item?.firstProductId}-200h.jpg)"
      z '.name',
        item?.name
