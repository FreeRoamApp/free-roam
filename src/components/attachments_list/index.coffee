z = require 'zorium'
_map = require 'lodash/map'

ImageViewOverlay = require '../image_view_overlay'
colors = require '../../colors'
config = require '../../config'

if window?
  require './index.styl'

PADDING = 4

module.exports = class AttachmentsList
  constructor: ({@model, @router, attachments}) ->
    @state = z.state
      attachments: attachments
      windowSize: @model.window.getSize()
      contentWidth: null

  afterMount: (@$$el) =>
    setTimeout =>
      checkIsReady = =>
        if @$$el and @$$el.clientWidth
          @state.set contentWidth: @$$el.clientWidth
        else
          setTimeout checkIsReady, 100
      checkIsReady()
    , 0 # give time for re-render...


  render: ({countPerRow, sizePx}) =>
    {attachments, windowSize, contentWidth} = @state.getValue()

    if sizePx
      widthPx = sizePx + PADDING * 2
      heightPx = sizePx
    else
      countPerRow ?= 4
      contentWidth ?= windowSize?.contentWidth
      widthPx = contentWidth / 4
      heightPx = contentWidth / 4 - PADDING * 2

    images = _map attachments, (attachment) =>
      {
        url: @model.image.getSrcByPrefix attachment.prefix, {size: 'large'}
        aspectRatio: attachment.aspectRatio
      }

    z '.z-attachments-list',
      _map attachments, (attachment, i) =>
        src = @model.image.getSrcByPrefix attachment.prefix, {size: 'small'}
        z '.attachment', {
          style:
            width: "#{widthPx}px"
            height: "#{heightPx}px"
        },
          z '.img',
            title: attachment.caption
            onclick: =>
              @model.overlay.open new ImageViewOverlay {
                @model
                @router
                images: images
                imageIndex: i
                imageData:
                  url: @model.image.getSrcByPrefix attachment.prefix, {
                    size: 'large'
                  }
                  aspectRatio: attachment.aspectRatio
              }
            style:
              backgroundImage: "url(#{src})"
