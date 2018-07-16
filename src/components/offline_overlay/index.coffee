z = require 'zorium'

PrimaryButton = require '../primary_button'

if window?
  require './index.styl'

module.exports = class OfflineOverlay
  constructor: ({@model, @isOffline}) ->
    @$closeButton = new PrimaryButton()

  render: =>
    z '.z-offline-overlay',
      @model.l.get 'offlineOverlay.text'
      z '.close-button',
        z @$closeButton,
          text: @model.l.get 'offlineOverlay.closeButtonText'
          isFullWidth: false
          onclick: =>
            @isOffline.next false
