z = require 'zorium'

SecondaryButton = require '../secondary_button'
FlatButton = require '../flat_button'

if window?
  require './index.styl'

B_IN_MB = 1024 * 1024

module.exports = class Settings
  constructor: ({@model, @router}) ->
    @$recordButton = new SecondaryButton()
    @$cacheSizeButton = new FlatButton()
    @$clearCacheButton = new FlatButton()

    @state = z.state {}

  render: =>
    {} = @state.getValue()

    z '.z-settings',
      z '.g-grid',
        if navigator?.serviceWorker
          z '.section',
            z '.title', @model.l.get 'settings.offlineMode'
            z '.description', @model.l.get 'settings.description'
            z '.actions',
              z @$recordButton,
                text: @model.l.get 'settings.startRecording'
                onclick: =>
                  @model.offlineData.record()
              z @$cacheSizeButton, {
                onclick: =>
                  @model.portal.call 'cache.getSizeByCacheName', {
                    cacheName: 'recorded'
                  }
                  .then (size) =>
                    size += localStorage?.offlineCache?.length or 0
                    mb = Math.round(100 * size / B_IN_MB) / 100
                    alert @model.l.get 'settings.sizeInfo', {
                      replacements:
                        size: "#{mb}mb"
                    }
                text: @model.l.get 'settings.checkCacheSize'
              }
              z @$clearCacheButton, {
                onclick: =>
                  @model.portal.call 'cache.clearByCacheName', {
                    cacheName: 'recorded'
                  }
                  delete localStorage.offlineCache
                text: @model.l.get 'settings.clearOfflineData'
              }
