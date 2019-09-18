z = require 'zorium'
RxReplaySubject = require('rxjs/ReplaySubject').ReplaySubject
RxBehaviorSubject = require('rxjs/BehaviorSubject').BehaviorSubject
RxObservable = require('rxjs/Observable').Observable
require 'rxjs/add/observable/of'
_map = require 'lodash/map'
_findIndex = require 'lodash/findIndex'
_clone = require 'lodash/clone'

Icon = require '../icon'
UploadOverlay = require '../upload_overlay'
UploadImagesPreview = require '../upload_images_preview'
VideoAttachmentDialog = require '../video_attachment_dialog'
colors = require '../../colors'
config = require '../../config'

if window?
  require './index.styl'

module.exports = class UploadImagesList
  constructor: (options) ->
    {@model, @router, @attachmentsValueStreams, uploadFn,
      requestTags, requestLocation} = options

    @$addImageIcon = new Icon()
    @$addVideoIcon = new Icon()

    @attachmentsValueStreams ?= new RxReplaySubject 1

    @multiImageData = new RxBehaviorSubject null
    @$uploadOverlay = new UploadOverlay {@model}
    @$uploadImagesPreview = new UploadImagesPreview {
      @multiImageData
      @model
      uploadFn
      requestTags
      requestLocation
      # TODO: there's probably a much cleaner way to do this and onProgress....
      onUploading: (dataUrl, {clientId}) =>
        {attachments} = @state.getValue()

        unless attachments?.concat
          attachments = []
        @attachmentsValueStreams.next RxObservable.of(attachments.concat [
          {
            type: 'image', isUploading: true, dataUrl, clientId
          }
        ])
      onProgress: (response, {clientId}) =>
        {attachments} = @state.getValue()

        attachmentIndex = _findIndex attachments, {clientId}
        attachments[attachmentIndex].progress = response.loaded / response.total
        @attachmentsValueStreams.next RxObservable.of attachments
      onUpload: (response, {clientId}) =>
        {caption, tags, id, prefix, location, aspectRatio} = response

        {attachments} = @state.getValue()

        attachmentIndex = _findIndex attachments, {clientId}
        attachments[attachmentIndex] = {
          type: 'image', aspectRatio, caption, tags, location, id, prefix
        }
        @attachmentsValueStreams.next RxObservable.of attachments
    }

    @state = z.state
      attachments: @attachmentsValueStreams.switch()
      $attachments: @attachmentsValueStreams.switch().map (attachments) ->
        _map attachments, (attachment) ->
          {attachment, $icon: new Icon()}

  render: ({onDone}) =>
    {attachments, $attachments} = @state.getValue()

    z '.z-upload-images-list',
        z '.add-image',
          z '.icon',
            z @$addImageIcon,
              icon: 'photo-add'
              isTouchTarget: false
              size: '32px'
              color: colors.$primary500Text
          z '.text',
            @model.l.get 'general.add'

          z '.upload-overlay',
            z @$uploadOverlay, {
              isMulti: true
              onSelect: ({files, dataUrls}) =>
                Promise.all _map files, (file, i) ->
                  new Promise (resolve) ->
                    img = new Image()
                    img.src = dataUrls[i]
                    img.onload = ->
                      resolve {
                        file
                        dataUrl: dataUrls[i]
                        width: img.width
                        height: img.height
                      }
                .then (multiImageData) =>
                  @multiImageData.next multiImageData
                  @model.overlay.open @$uploadImagesPreview
            }
        z '.add-video', {
          onclick: =>
            @model.overlay.open new VideoAttachmentDialog {
              @model, onSave: (url) =>
                youtubeId = url.match(config.YOUTUBE_ID_REGEX)?[1]
                if youtubeId
                  {attachments} = @state.getValue()
                  attachments.push {
                    type: 'video'
                    prefix: youtubeId
                  }
                  @attachmentsValueStreams.next RxObservable.of attachments
            }
        },
          z '.icon',
            z @$addVideoIcon,
              icon: 'video-add'
              isTouchTarget: false
              size: '32px'
              color: colors.$bgText54
          z '.text',
            @model.l.get 'general.add'

        _map $attachments, ({attachment, $icon}, i) =>
          {dataUrl, prefix, isUploading, progress, type} = attachment
          if attachment.type is 'video'
            src = "https://img.youtube.com/vi/#{attachment.prefix}/sddefault.jpg"
          else
            src = @model.image.getSrcByPrefix prefix, {size: 'small'}
          z '.attachment', {
            className: z.classKebab {isUploading}
            oncontextmenu: (e) =>
              e.preventDefault()
              newAttachments = _clone attachments
              newAttachments.splice i, 1
              @attachmentsValueStreams.next RxObservable.of newAttachments
          },
            z '.image', {
              style:
                backgroundImage: "url(#{dataUrl or src})"
                backgroundColor: if type is 'video'
                  colors.$secondary500
            },
              if type is 'video'
                z $icon,
                  icon: 'youtube'
                  color: colors.$secondary500Text
            z '.progress',
              z '.bar', {
                style:
                  width: "#{100 * (progress or 0)}%"
              }
              z '.text',
                if progress is 1 and isUploading
                  @model.l.get 'general.processing'
                else if isUploading
                  "#{Math.round(100 * (progress or 0))}%"
                else
                  @model.l.get 'general.ready'
