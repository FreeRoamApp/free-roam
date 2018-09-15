z = require 'zorium'

Icon = require '../icon'
ButtonBack = require '../button_back'
AppBar = require '../app_bar'
colors = require '../../colors'
config = require '../../config'

if window?
  require './index.styl'

module.exports = class ImageViewOverlay
  constructor: ({@model, @router, imageData, @overlay$}) ->
    @$buttonBack = new ButtonBack {@router}
    @$appBar = new AppBar {@model}

    @state = z.state
      imageData: imageData
      windowSize: @model.window.getSize()
      appBarHeight: @model.window.getAppBarHeight()

  afterMount: =>
    @router.onBack =>
      @overlay$.next null

  beforeUnmount: =>
    @router.onBack null

  render: =>
    {windowSize, appBarHeight, imageData} = @state.getValue()

    imageData ?= {}

    windowHeight = windowSize.height - appBarHeight

    if imageData.aspectRatio
      imageAspectRatio = imageData.aspectRatio
      windowAspectRatio = windowSize.width / windowHeight

      if imageAspectRatio > windowAspectRatio
        imageWidth = windowSize.width
        imageHeight = imageWidth / imageAspectRatio
      else
        imageHeight = windowHeight
        imageWidth = imageHeight * imageAspectRatio
    else
      imageHeight = undefined
      imageWidth = undefined

    z '.z-image-view-overlay',
      z @$appBar, {
        title: @model.l.get 'conversationImageView.title'
        $topLeftButton: z @$buttonBack, {
          color: colors.$header500Icon
          onclick: =>
            @overlay$.next null
        }
      }
      z 'img',
        src: imageData.url
        width: imageWidth
        height: imageHeight
