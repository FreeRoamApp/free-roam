z = require 'zorium'
_map = require 'lodash/map'

ImageViewOverlay = require '../image_view_overlay'
colors = require '../../colors'
config = require '../../config'

if window?
  require './index.styl'

module.exports = class AttachmentsList
  constructor: ({@model, @router, attachments}) ->
    @state = z.state
      attachments: attachments

  render: =>
    {attachments} = @state.getValue()

    images = _map attachments, (attachment) =>
      {
        url: @model.image.getSrcByPrefix attachment.prefix, {size: 'large'}
        aspectRatio: attachment.aspectRatio
      }

    z '.z-attachments-list',
      _map attachments, (attachment, i) =>
        src = @model.image.getSrcByPrefix attachment.prefix, {size: 'small'}
        z '.attachment',
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
