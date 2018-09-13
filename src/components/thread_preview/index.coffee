z = require 'zorium'
_find = require 'lodash/find'

if window?
  require './index.styl'

EmbeddedVideo = require '../embedded_video'
config = require '../../config'
colors = require '../../colors'

PADDING = 16

module.exports = class ThreadPreview
  constructor: ({@model, thread}) ->
    videoAttachment = _find thread?.attachments, {type: 'video'}
    if videoAttachment
      @$embeddedVideo = new EmbeddedVideo {
        @model
        videoAttachment
      }

    @state = z.state
      thread: thread
      windowSize: @model.window.getSize()

  render: ({width} = {}) =>
    {windowSize, thread} = @state.getValue()

    unless thread
      return

    imageAttachment = _find thread.attachments, {type: 'image'}

    z '.z-thread-preview',
      if @$embeddedVideo
        z @$embeddedVideo, {width}
      else if imageAttachment
        mediaSrc = imageAttachment.largeSrc or imageAttachment.src
        z 'img.image', {
          src: mediaSrc?.split(' ')[0]
        }
