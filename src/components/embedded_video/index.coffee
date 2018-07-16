z = require 'zorium'
Environment = require '../../services/environment'

config = require '../../config'

if window?
  require './index.styl'

MAX_WIDTH_PX = 700
PADDING_PX = 16

module.exports = class EmbeddedVideo
  constructor: ({@model, videoAttachment}) ->
    unless videoAttachment.map
      @videoAttachment = videoAttachment
    @state = z.state
      windowSize: @model.window.getSize()
      videoAttachment: @videoAttachment

  render: ({width} = {}) =>
    {windowSize, videoAttachment} = @state.getValue()

    width ?= Math.min MAX_WIDTH_PX, windowSize.width - 16 * 2
    heightAspect = if videoAttachment?.aspectRatio \
                   then 1 / videoAttachment.aspectRatio
                   else 9 / 16
    height = width * heightAspect

    isNativeApp = Environment.isNativeApp 'freeroam'

    z '.z-embedded-video',
      if videoAttachment.mp4Src
        z 'video.video', {
          width: width
          attributes:
            loop: true
            controls: true
            autoplay: true
        },
          z 'source',
            type: 'video/mp4'
            src: videoAttachment.mp4Src
          z 'source',
            type: 'video/mp4'
            src: videoAttachment.webmSrc
      else if isNativeApp
        z '.thumbnail', {
          onclick: =>
            @model.portal.call 'browser.openWindow', {
              url: videoAttachment.src
              target: '_system'
            }
        },
          z 'img', {
            width
            height
            src: 'https://img.youtube.com/vi/nnkBzktQuM0/hqdefault.jpg'
          }
          z '.play'
      else
        z 'iframe',
          width: width
          height: height
          src: @src or videoAttachment.src
          frameborder: 0
          allow: 'autoplay; encrypted-media'
          allowfullscreen: true
          webkitallowfullscreen: true
