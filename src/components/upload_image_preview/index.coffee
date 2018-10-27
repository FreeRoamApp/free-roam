z = require 'zorium'

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

    @state = z.state
      imageData: @imageData
      isUploading: false
      windowSize: @model.window.getSize()

  render: ({iconName} = {}) =>
    {imageData, isUploading, windowSize} = @state.getValue()

    imageData ?= {}

    iconName ?= 'upload'

    if imageData.width
      imageAspectRatio = imageData.aspectRatio or (
        imageData.width / imageData.height
      )
      windowAspectRatio = windowSize.width / windowSize.height
      # 3:1, 1:1
      if imageAspectRatio > windowAspectRatio
        previewWidth = Math.min windowSize.width, imageData.width
        previewHeight = previewWidth / imageAspectRatio
      else
        previewHeight = Math.min windowSize.height, imageData.height
        previewWidth = previewHeight * imageAspectRatio
    else
      previewHeight = undefined
      previewWidth = undefined

    z '.z-upload-image-preview',
      z 'img',
        src: imageData.dataUrl
        width: previewWidth
        height: previewHeight
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
          colors:
            c500: colors.$primary500
          $icon: z @$uploadIcon, {
            icon: if isUploading then 'ellipsis' else iconName
            isTouchTarget: false
            color: colors.$primary500Text
          }
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
