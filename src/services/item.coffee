_cloneDeep = require 'lodash/cloneDeep'
_defaults = require 'lodash/defaults'
_find = require 'lodash/find'
_findIndex = require 'lodash/findIndex'
_each = require 'lodash/each'

# TODO: cleanup (delete fns from supernova we're not using)

class ItemService
  getWidthFromHeight: (height) ->
    scale = height / 1430
    return scale * 930

  getHeightFromWidth: (width) ->
    scale = width / 930
    return scale * 1430

  getSizesFromWidth: (width, {isInsert, name} = {}) ->
    scale = width / 930

    return {
      imageWidth: if isInsert then width * 0.975 else width * 0.9
      nameFontSize: if name?.length > 16 then scale * 75 else scale * 95
      nameLineHeight: scale * 130
      numberFontSize: scale * 60
      rarityFontSize: scale * 60
      countOverlayFontSize: scale * 200
      crystalBorderRadius: scale * 320
      insertBorderRadius: scale * 60
    }

  # same code in mittens for fns below. TODO: make separate lib

  removeItem: (items, findItem, count = 1) =>
    items = _cloneDeep items
    index = @findItem items, findItem, {findIndex: true}
    if index isnt -1 and items[index]?.count > count
      items[index].count -= count
    else if index isnt -1
      items.splice index, 1
    items

  removeItemKey: (itemKeys, findItemKey, count = 1) =>
    itemKeys = _cloneDeep itemKeys
    index = @findItemKey itemKeys, findItemKey, {findIndex: true}
    if index isnt -1 and itemKeys[index]?.count > count
      itemKeys[index].count -= count
    else if index isnt -1
      itemKeys.splice index, 1
    itemKeys

  addItemKey: (itemKeys, addedItemKey, count = 1) =>
    itemKeys = _cloneDeep itemKeys
    index = @findItemKey itemKeys, addedItemKey, {findIndex: true}
    if index isnt -1
      itemKeys[index].count += count
    else
      itemKeys.push _defaults {count: count}, addedItemKey
    itemKeys

  addItem: (items, addedItem, count = 1) =>
    items = _cloneDeep items
    index = @findItem items, addedItem, {findIndex: true}
    if index isnt -1
      items[index].count += count
    else
      items.push _defaults {count: count}, addedItem
    items

  addItemKeys: (itemKeys, ids) =>
    _each ids, (id) =>
      itemKeys = @addItemKey itemKeys, id
    itemKeys

  findItemKey: (itemKeys, findItemKey, {findIndex} = {}) ->
    findIndex ?= false

    findFn = if findIndex then _findIndex else _find
    findFn itemKeys, (itemKey) ->
      findItemKey.key is itemKey.key

  findItem: (items, findItem, {findIndex} = {}) ->
    findIndex ?= false

    findFn = if findIndex then _findIndex else _find
    findFn items, (item) ->
      findItem.item.key is item.item.key


  addItemByItemKey: (itemKeys, findItemKey, item) =>
    itemKeys = _cloneDeep itemKeys
    index = @findItemKey itemKeys, findItemKey, {findIndex: true}
    if index is -1
      throw new Error 'itemKey not found'

    itemKeys[index].items ?= []
    itemKeys[index].items.push item
    itemKeys

module.exports = new ItemService()
