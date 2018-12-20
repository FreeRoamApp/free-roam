_map = require 'lodash/map'

module.exports = class Base
  getCached$: (id, component, args...) =>
    @cachedComponents or= []

    if @cachedComponents[id]
      return @cachedComponents[id]
    else
      $component = new component args...
      @cachedComponents[id] = $component
      return $component

  fadeInWhenLoaded: (url) =>
    console.log 'call fade'
    @isImageLoaded = @model.image.isLoaded url
    console.log 'check', @isImageLoaded, url
    unless @isImageLoaded
      @model.image.load url
      .then =>
        # don't want to re-render entire state every time a pic loads in
        @$$el?.classList.add 'is-image-loaded'
        @isImageLoaded = true

  onDragOver: (e) =>
    if isBefore(@$$dragEl, e.target)
      e.target.parentNode.insertBefore @$$dragEl, e.target
    else
      e.target.parentNode.insertBefore @$$dragEl, e.target.nextSibling

  onDragEnd: =>
    @$$dragEl = null
    order = _map @$$el.querySelectorAll('.draggable'), ({dataset}) ->
      dataset.id
    @onReorder order

  onDragStart: (e) =>
    e.dataTransfer.effectAllowed = 'move'
    e.dataTransfer.setData 'text/plain', null
    @$$dragEl = e.target

  isBefore = (el1, el2) ->
    if el2.parentNode is el1.parentNode
      cur = el1.previousSibling
      while cur
        if cur is el2
          return true
        cur = cur.previousSibling
    false

  afterMount: (@$$el) =>
    @isImageLoaded = false
    clearTimeout @clearCacheTimeout

  beforeUnmount: (cachedElStoreTimeMs) =>
    if cachedElStoreTimeMs
      @clearCacheTimeout = setTimeout =>
        @cachedComponents = []
      , cachedElStoreTimeMs
    else
      @cachedComponents = []
