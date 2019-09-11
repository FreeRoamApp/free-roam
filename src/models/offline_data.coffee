module.exports = class OfflineDataModel
  constructor: ({@exoid, @portal, @l, @statusBar}) ->
    @isRecording = false

  record: =>
    @isRecording = true
    @statusBar.open {
      text: @l.get 'status.recordingData'
      onclick: @save
    }
    @exoid.invalidateAll()
    setTimeout =>
      @exoid.disableInvalidation()
      # @exoid.getCacheStream().subscribe (cache) ->
      #   console.log 'cache', JSON.stringify(cache).length
      @exoid.getCacheStream().subscribe (cache) =>
        console.log cache

      @portal.call 'cache.startRecording'
    , 0

  save: =>
    @isRecording = false
    @exoid.getCacheStream().take(1).subscribe (cache) =>
      @exoid.enableInvalidation()
      localStorage?.offlineCache = JSON.stringify cache
      @statusBar.close()
    @portal.call 'cache.stopRecording'
