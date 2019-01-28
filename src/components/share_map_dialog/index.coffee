z = require 'zorium'

Dialog = require '../dialog'
Spinner = require '../spinner'
colors = require '../../colors'
config = require '../../config'

if window?
  require './index.styl'


module.exports = class ShareMapDialog
  constructor: ({@model, @trip, shareInfo}) ->
    @$dialog = new Dialog {
      onLeave: =>
        @model.overlay.close()
    }
    @$spinner = new Spinner()

    @state = z.state {
      shareInfo
      @trip
    }

  render: =>
    {trip, shareInfo} = @state.getValue()

    cacheBust = new Date(trip?.lastUpdateTime).getTime()
    prefix = trip?.imagePrefix or 'trips/default'
    tripImage = @model.image.getSrcByPrefix(
      prefix, {size: 'large', cacheBust}
    )

    isLoading = not trip?

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
                  src: tripImage
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
                  # not working properly
                  # z 'a.action', {
                  #   href: tripImage
                  #   attributes:
                  #     download: 'travel_map.png'
                  #   onclick: ->
                  #     ga? 'send', 'event', 'trip', 'share', 'download'
                  # },
                  #   @model.l.get 'shareMapDialog.saveImage'
        cancelButton:
          text: @model.l.get 'general.done'
          onclick: =>
            @model.overlay.close()
