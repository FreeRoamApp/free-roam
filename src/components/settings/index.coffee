z = require 'zorium'

SecondaryButton = require '../secondary_button'
FlatButton = require '../flat_button'
Environment = require '../../services/environment'

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
        if not navigator?.serviceWorker
          z '.section',
            z 'p', 'Due to a bug I\'m currently trying to fix, offline mode is temporarily not available in the app.'
            z 'p', 'However, you can access it through the website on your phone or computer'
            z '.actions',
              z @$recordButton,
                text: 'Visit website'
                onclick: =>
                  @model.portal.call 'browser.openWindow', {
                    url: 'https://freeroam.app'
                    target: '_system'
                  }
            z 'p', 'Sorry for the inconvenience!'
        else
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
