z = require 'zorium'
Environment = require '../../services/environment'

config = require '../../config'

if window?
  require './index.styl'

MAX_WIDTH_PX = 700
PADDING_PX = 16

module.exports = class EmbeddedVideo
  constructor: ({@model, video}) ->
    unless video.map
      @video = video
    @state = z.state
      windowSize: @model.window.getSize()
      video: @video

  render: ({width} = {}) =>
    {windowSize, video} = @state.getValue()

    width ?= Math.min MAX_WIDTH_PX, windowSize.width - 16 * 2
    heightAspect = if video?.aspectRatio \
                   then 1 / video.aspectRatio
                   else 9 / 16
    height = width * heightAspect

    userAgent = @model.window.getUserAgent()
    isNativeApp = Environment.isNativeApp 'freeroam', {userAgent}

    z '.z-embedded-video',
      if isNativeApp
        z '.thumbnail', {
          onclick: =>
            @model.portal.call 'browser.openWindow', {
              url: "https://www.youtube.com/watch?v=#{video.sourceId}"
              target: '_system'
            }
        },
          z 'img', {
            width
            height
            src: "https://img.youtube.com/vi/#{video.sourceId}/hqdefault.jpg"
          }
          z '.play'
      else
        z 'iframe',
          width: width
          height: height
          src: "https://www.youtube.com/embed/#{video.sourceId}"
          frameborder: 0
          allow: 'autoplay; encrypted-media'
          allowfullscreen: true
          webkitallowfullscreen: true
      # if video.mp4Src
      #   z 'video.video', {
      #     width: width
      #     attributes:
      #       loop: true
      #       controls: true
      #       autoplay: true
      #   },
      #     z 'source',
      #       type: 'video/mp4'
      #       src: video.mp4Src
      #     z 'source',
      #       type: 'video/mp4'
      #       src: video.webmSrc
      # else if isNativeApp
      #   z '.thumbnail', {
      #     onclick: =>
      #       @model.portal.call 'browser.openWindow', {
      #         url: video.src
      #         target: '_system'
      #       }
      #   },
      #     z 'img', {
      #       width
      #       height
      #       src: 'https://img.youtube.com/vi/nnkBzktQuM0/hqdefault.jpg'
      #     }
      #     z '.play'
      # else
      #   z 'iframe',
      #     width: width
      #     height: height
      #     src: @src or video.src
      #     frameborder: 0
      #     allow: 'autoplay; encrypted-media'
      #     allowfullscreen: true
      #     webkitallowfullscreen: true
