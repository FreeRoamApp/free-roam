PortalGun = require 'portal-gun'

module.exports = class Portal
  constructor: ({@cache}) ->
    @portal = new PortalGun()

    # TODO: set fn for all clients. need to update portal-gun to handle
    # responding to all clients better
    @onPushFn = null
    @contextId = null

  listen: =>
    @portal.listen()
    @portal.on 'top.onData', @topOnData
    @portal.on 'push.setContextId', @pushSetContextId
    @portal.on 'cache.deleteHtmlCache', @deleteHtmlCache
    @portal.on 'cache.startRecording', @startRecording
    @portal.on 'cache.stopRecording', @stopRecording
    @portal.on 'cache.getSizeByCacheName', @getSizeByCacheName
    @portal.on 'cache.clearByCacheName', @clearByCacheName
    @portal.on 'cache.getVersion', ->
      Promise.resolve '|HASH|'
    # portal.on 'cache.onUpdateAvailable', onUpdateAvailable

  topOnData: (fn) =>
    @onPushFn = fn

  pushSetContextId: (options) =>
    @contextId = options.contextId

  deleteHtmlCache: =>
    console.log 'portal update cache', "html:#{@cache.cachesFiles.html.version}"
    cache = @cache.cachesFiles.html
    @cache.updateCache cache, 'html'

  startRecording: =>
    @cache.isRecording = true

  stopRecording: =>
    @cache.isRecording = false

  getSizeByCacheName: ({cacheName}) =>
    @cache.getSizeByCacheName cacheName

  clearByCacheName: ({cacheName}) =>
    @cache.clearByCacheName cacheName
