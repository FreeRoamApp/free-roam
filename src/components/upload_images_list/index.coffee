z = require 'zorium'
RxReplaySubject = require('rxjs/ReplaySubject').ReplaySubject
RxBehaviorSubject = require('rxjs/BehaviorSubject').BehaviorSubject
RxObservable = require('rxjs/Observable').Observable
require 'rxjs/add/observable/of'
_map = require 'lodash/map'
_findIndex = require 'lodash/findIndex'

Icon = require '../icon'
UploadOverlay = require '../upload_overlay'
UploadImagesPreview = require '../upload_images_preview'
colors = require '../../colors'

if window?
  require './index.styl'

module.exports = class UploadImagesList
  constructor: (options) ->
    {@model, @router, @attachmentsValueStreams, uploadFn,
      requestTags, requestLocation} = options

    @$addImageIcon = new Icon()

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

        attachments or= []
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

  render: ({onDone}) =>
    {attachments} = @state.getValue()

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
        _map attachments, ({dataUrl, prefix, isUploading, progress}) =>
          console.log progress, isUploading
          src = @model.image.getSrcByPrefix prefix, {size: 'small'}
          z '.attachment', {
            className: z.classKebab {isUploading}
          },
            z '.image',
              style:
                backgroundImage: "url(#{dataUrl or src})"
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
