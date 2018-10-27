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
