z = require 'zorium'

Icon = require '../icon'
ButtonBack = require '../button_back'
AppBar = require '../app_bar'
colors = require '../../colors'
config = require '../../config'

if window?
  require './index.styl'

module.exports = class ConversationImageView
  constructor: ({@model, @router}) ->
    @$buttonBack = new ButtonBack {@router}
    @$appBar = new AppBar {@model}

    @state = z.state
      imageData: @model.imageViewOverlay.getImageData()
      windowSize: @model.window.getSize()
      appBarHeight: @model.window.getAppBarHeight()

  afterMount: =>
    @router.onBack =>
      @model.imageViewOverlay.setImageData null

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

    z '.z-conversation-image-view',
      z @$appBar, {
        title: @model.l.get 'conversationImageView.title'
        $topLeftButton: z @$buttonBack, {
          color: colors.$header500Icon
          onclick: =>
            @model.imageViewOverlay.setImageData null
        }
      }
      z 'img',
        src: imageData.url
        width: imageWidth
        height: imageHeight
