z = require 'zorium'
RxBehaviorSubject = require('rxjs/BehaviorSubject').BehaviorSubject

Icon = require '../icon'
Fab = require '../fab'
colors = require '../../colors'
config = require '../../config'

if window?
  require './index.styl'

module.exports = class UploadImagePreview
  constructor: ({@imageData, @model, @onUpload, @uploadFn}) ->
    @$sendIcon = new Icon()
    @$closeImagePreviewIcon = new Icon()
    @$uploadImageFab = new Fab()
    @$uploadIcon = new Icon()

    @rotationValueSubject = new RxBehaviorSubject null

    @state = z.state
      imageData: @imageData.map (imageData) =>
        if imageData
          @model.image.parseExif(
            imageData?.file, null, @rotationValueSubject
          )
        imageData
      isUploading: false
      rotation: @rotationValueSubject
      windowSize: @model.window.getSize()

  beforeUnmount: =>
    @rotationValueSubject.next null

  render: ({iconName} = {}) =>
    {imageData, rotation, isUploading, windowSize} = @state.getValue()

    imageData ?= {}

    iconName ?= 'upload'

    isRotated = rotation in ['rotate-90', 'rotate-270']
    maxWidth = Math.min windowSize.width, 600

    if imageData.width
      imageAspectRatio = imageData.aspectRatio or (
        imageData.width / imageData.height
      )
      windowAspectRatio = windowSize.width / windowSize.height
      # 3:1, 1:1
      if imageAspectRatio > windowAspectRatio
        previewWidth = Math.min maxWidth, imageData.width
        previewHeight = previewWidth / imageAspectRatio
      else
        previewHeight = Math.min windowSize.height, imageData.height
        previewWidth = previewHeight * imageAspectRatio
    else
      previewHeight = undefined
      previewWidth = undefined

    z '.z-upload-image-preview',
      z ".image-wrapper.#{rotation or 'no-rotation'}", {
        style:
          height: if isRotated \
                  then "#{previewWidth + 50}px"
                  else "#{previewHeight + 50}px"
          # width: if isRotated \
          #         then "#{previewHeight}px"
          #         else "#{previewWidth}px"
      },
        z "img",
          src: imageData.dataUrl
          width: previewWidth
          height: previewHeight
          style:
            marginTop: if isRotated \
                       then "#{50 + (previewWidth - previewHeight) / 2}px"
                       else '50px'
            marginLeft: if isRotated \
                       then "#{(previewHeight - previewWidth) / 2}px"
                       else 0
      z '.close',
        z @$closeImagePreviewIcon,
          icon: 'close'
          color: colors.$white
          isTouchTarget: true
          onclick: =>
            @imageData.next null
            @model.overlay.close()
      z '.fab',
        z @$uploadImageFab,
          isPrimary: true
          icon: if isUploading then 'ellipsis' else iconName
          onclick: =>
            if not isUploading and not @isUploading
              @isUploading = true # instant, w/o we sometimes get 2 uploads
              @state.set isUploading: true
              @uploadFn imageData.file
              .then (image) =>
                @onUpload image
                @state.set isUploading: false
                @isUploading = false
                @imageData.next null
                @model.overlay.close()
