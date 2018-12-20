z = require 'zorium'

Dialog = require '../dialog'
Spinner = require '../spinner'
colors = require '../../colors'
config = require '../../config'

if window?
  require './index.styl'


module.exports = class ShareMapDialog
  constructor: ({@model, @isLoading, @imagePrefix, @blob, shareInfo}) ->
    @$dialog = new Dialog {
      onLeave: =>
        @model.overlay.close()
    }
    @$spinner = new Spinner()

    @state = z.state {
      shareInfo
      @isLoading
      @imagePrefix
      @blob
    }

  render: =>
    {shareInfo, isLoading, imagePrefix, blob} = @state.getValue()

    createObjectURL = window?.URL?.createObjectURL or
                      window?.webkitURL?.createObjectURL

    z '.z-share-map-dialog',
      z @$dialog,
        isWide: true
        isVanilla: true
        $title: @model.l.get 'shareMapDialog.title'
        $content:
          z '.z-share-map-dialog_dialog',
            if isLoading
              z @$spinner
            else
              z '.content',
                z 'img.preview', {
                  src: @model.image.getSrcByPrefix imagePrefix
                }
                z '.actions',
                  z '.action', {
                    onclick: =>
                      ga? 'send', 'event', 'trip', 'share', 'facebook'
                      @model.portal.call 'facebook.share', {
                        text: shareInfo.text
                        url: shareInfo.url
                      }
                  },
                    @model.l.get 'shareMapDialog.shareFacebook'
                  # z '.action', {
                  #   onclick: =>
                  #     @model.portal.call 'instagram.share', {
                  #       text: shareInfo.text
                  #       url: shareInfo.url
                  #     }
                  # },
                  #   @model.l.get 'shareMapDialog.shareInstagram'
                  z '.action', {
                    onclick: =>
                      ga? 'send', 'event', 'trip', 'share', 'any'
                      @model.portal.call 'share.any', {
                        text: shareInfo.text
                        url: shareInfo.url
                      }
                  },
                    @model.l.get 'shareMapDialog.shareOther'
                  z 'a.action', {
                    href: if blob
                      createObjectURL blob
                    attributes:
                      download: 'travel_map.png'
                    onclick: ->
                      ga? 'send', 'event', 'trip', 'share', 'download'
                  },
                    @model.l.get 'shareMapDialog.saveImage'
        cancelButton:
          text: @model.l.get 'general.done'
          onclick: =>
            @model.overlay.close()
