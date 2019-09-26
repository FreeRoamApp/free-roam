z = require 'zorium'

Dialog = require '../dialog'
config = require '../../config'
colors = require '../../colors'

if window?
  require './index.styl'

module.exports = class AddPlaceDialog
  constructor: ({@model, @router, @location}) ->
    @$dialog = new Dialog {
      onLeave: =>
        @model.overlay.close()
    }

  render: =>
    z '.z-add-place-dialog',
        z @$dialog,
          isVanilla: true
          isWide: true
          $title: @model.l.get 'addPlaceDialog.title'
          $content:
            z '.z-add-place-dialog_dialog',
              @router.link z 'a.type', {
                href: @router.get 'newCampground', {}, {
                  qs:
                    location: Math.round(@location.lat * 1000) / 1000 +
                              ',' +
                              Math.round(@location.lon * 1000) / 1000
                }
              },
                @model.l.get 'drawer.newCampground'
              @router.link z 'a.type', {
                href: @router.get 'newOvernight', {}, {
                  qs:
                    location: Math.round(@location.lat * 1000) / 1000 +
                              ',' +
                              Math.round(@location.lon * 1000) / 1000
                }
              },
                @model.l.get 'drawer.newOvernight'
              @router.link z 'a.type', {
                href: @router.get 'newAmenity', {}, {
                  qs:
                    location: Math.round(@location.lat * 1000) / 1000 +
                              ',' +
                              Math.round(@location.lon * 1000) / 1000
                }
              },
                @model.l.get 'drawer.newFacility'

          cancelButton:
            text: @model.l.get 'general.cancel'
            onclick: =>
              @model.overlay.close()
