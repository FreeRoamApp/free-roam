z = require 'zorium'

Dialog = require '../dialog'
colors = require '../../colors'
config = require '../../config'

if window?
  require './index.styl'

module.exports = class GetAppDialog
  constructor: ({@model}) ->
    @$dialog = new Dialog {
      onLeave: =>
        @model.overlay.close()
    }

  render: =>
    iosAppUrl = config.IOS_APP_URL
    googlePlayAppUrl = config.GOOGLE_PLAY_APP_URL

    z '.z-get-app-dialog',
      z @$dialog,
        isVanilla: true
        $title: @model.l.get 'getAppDialog.title'
        $content:
          z '.z-get-app-dialog_dialog',
            z '.badge.ios', {
              onclick: =>
                @model.portal.call 'browser.openWindow',
                  url: iosAppUrl
                  target: '_system'
            }
            z '.badge.android', {
              onclick: =>
                @model.portal.call 'browser.openWindow',
                  url: googlePlayAppUrl
                  target: '_system'
            }
            z '.text',
              @model.l.get 'getAppDialog.text'
        cancelButton:
          text: @model.l.get 'general.cancel'
          onclick: =>
            @model.overlay.close()
