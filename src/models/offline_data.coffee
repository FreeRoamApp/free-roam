config = require '../config'

module.exports = class OfflineDataModel
  constructor: ({@exoid, @portal, @l, @statusBar}) -> null

  record: =>
    @statusBar.open {
      text: @l.get 'status.recordingData'
      onclick: @save
    }
    @exoid.disableInvalidation()
    # @exoid.getCacheStream().subscribe (cache) ->
    #   console.log 'cache', JSON.stringify(cache).length

    @portal.call 'cache.startRecording'

  save: =>
    @exoid.getCacheStream().take(1).subscribe (cache) =>
      @exoid.enableInvalidation()
      localStorage?.offlineCache = JSON.stringify cache
      @statusBar.close()
    @portal.call 'cache.stopRecording'
