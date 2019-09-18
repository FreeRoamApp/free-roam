z = require 'zorium'
_map = require 'lodash/map'

Icon = require '../icon'
ImageViewOverlay = require '../image_view_overlay'
colors = require '../../colors'
config = require '../../config'

if window?
  require './index.styl'

PADDING = 4

# TODO: combine with Attachments

module.exports = class AttachmentsList
  constructor: ({@model, @router, attachments, more, limit}) ->
    @state = z.state
      attachments: attachments
      windowSize: @model.window.getSize()
      contentWidth: null
      more: more
      attachments: attachments.map (attachments) ->
        if limit and attachments?.slice
          attachments = attachments.slice 0, limit
        else
          attachments = attachments

        _map attachments, (attachment) ->
          {attachment, $icon: new Icon()}

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
    {attachments, more, windowSize, contentWidth} = @state.getValue()

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
      _map attachments, ({attachment, $icon}, i) =>
        if attachment.type is 'video'
          src = "https://img.youtube.com/vi/#{attachment.prefix}/sddefault.jpg"
        else
          src = @model.image.getSrcByPrefix attachment.prefix, {size: 'small'}
        z '.attachment-wrapper', {
          style:
            width: "#{widthPx}px"
            height: "#{heightPx}px"
        },
          z '.attachment',
            if more and i is attachments.length - 1
              z 'a.more', {
                href: more.path
                onclick: (e) =>
                  e.preventDefault()
                  e.stopPropagation()
                  if more.onclick
                    more.onclick()
                  else
                    @router.goPath more.path
              },
                z '.text', "+#{more.count}"
            z '.img',
              title: attachment.caption
              onclick: =>
                if attachment.type is 'video'
                  @model.portal.call 'browser.openWindow', {
                    url:
                      "https://youtube.com/watch?v=#{attachment.prefix}"
                  }

                else
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
            if attachment.type is 'video'
              z '.icon',
                z $icon,
                  icon: 'youtube'
                  color: colors.$white
                  size: '30px'
