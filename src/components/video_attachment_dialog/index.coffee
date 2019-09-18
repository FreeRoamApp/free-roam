z = require 'zorium'
RxBehaviorSubject = require('rxjs/BehaviorSubject').BehaviorSubject

PrimaryInput = require '../primary_input'
Dialog = require '../dialog'
colors = require '../../colors'
config = require '../../config'

if window?
  require './index.styl'


module.exports = class GoogleMapsWarningDialog
  constructor: ({@model, @onSave}) ->
    @$dialog = new Dialog {
      onLeave: =>
        @model.overlay.close()
    }

    @videoUrlSubject = new RxBehaviorSubject ''

    @$urlInput = new PrimaryInput
      value: @videoUrlSubject
      error: new RxBehaviorSubject null


  render: =>
    z '.z-video-attachment-dialog',
      z @$dialog,
        isWide: true
        isVanilla: true
        $title: @model.l.get 'videoAttachmentDialog.title'
        $content:
          z '.z-video-attachment-dialog_dialog',
            z @$urlInput,
              hintText: @model.l.get 'videoAttachmentDialog.videoHint'
        cancelButton:
          text: @model.l.get 'general.cancel'
          onclick: =>
            @model.overlay.close()
        submitButton:
          text: @model.l.get 'general.save'
          onclick: =>
            @onSave @videoUrlSubject.getValue()
            @model.overlay.close()
