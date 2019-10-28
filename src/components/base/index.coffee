_map = require 'lodash/map'
_forEach = require 'lodash/forEach'

getDraggable = (el, tries = 0) ->
  parent = el.parentNode
  # go up until we get the draggable class
  maxTries = 8
  if tries < maxTries and parent.className.indexOf('draggable') is -1
    parent = getDraggable parent, tries + 1
  else
    parent

isBefore = (el1, el2) ->
  el1Draggable = getDraggable el1
  el2Draggable = getDraggable el2
  if el2Draggable is el1Draggable
    cur = el1.previousSibling
    while cur
      if cur is el2
        return true
      cur = cur.previousSibling
  false

module.exports = class Base
  getCached$: (id, component, args...) =>
    @cachedComponents or= []

    if @cachedComponents[id]
      return @cachedComponents[id]
    else
      $component = new component args...
      @cachedComponents[id] = $component
      return $component

  getImageLoadHashByUrl: (url) =>
    hash = @model.image.getHash url
    isImageLoaded = @model.image.isLoadedByHash hash
    if isImageLoaded
      return 'is-image-loaded'
    else
      @model.image.load url
      .then =>
        # don't want to re-render entire state every time a pic loads in
        all = document.querySelectorAll(".image-loading-#{hash}")
        _forEach all, (el) -> el.classList.add 'is-image-loaded'
      return "image-loading-#{hash}"

  fadeInWhenLoaded: (url) =>
    @isImageLoaded = @model.image.isLoaded url
    unless @isImageLoaded
      @model.image.load url
      .then =>
        # don't want to re-render entire state every time a pic loads in
        @$$el?.classList.add 'is-image-loaded'
        @isImageLoaded = true

  onDragOver: (e) =>
    draggable = getDraggable e.target
    if isBefore(@$$dragEl, draggable)
      draggable.parentNode.insertBefore @$$dragEl, draggable
    else
      draggable.parentNode.insertBefore @$$dragEl, draggable.nextSibling

  onDragEnd: =>
    @$$dragEl = null
    order = _map @$$el.querySelectorAll('.draggable'), ({dataset}) ->
      dataset.id
    @onReorder order

  onDragStart: (e) =>
    e.dataTransfer.effectAllowed = 'move'
    e.dataTransfer.setData 'text/plain', null
    @$$dragEl = e.target

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
