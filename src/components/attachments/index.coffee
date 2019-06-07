z = require 'zorium'
_map = require 'lodash/map'
RxObservable = require('rxjs/Observable').Observable
require 'rxjs/add/observable/of'

ImageViewOverlay = require '../image_view_overlay'
Spinner = require '../spinner'
colors = require '../../colors'
config = require '../../config'

if window?
  require './index.styl'

module.exports = class Attachments
  constructor: ({@model, @router, attachments, limit}) ->
    @$spinner = new Spinner()

    @state = z.state
      me: @model.user.getMe()
      attachments: attachments.map (attachments) ->
        if limit
          attachments.slice 0, limit
        else
          attachments

  render: =>
    {me, attachments, attachments} = @state.getValue()

    images = _map attachments, (attachment) =>
      {
        url: @model.image.getSrcByPrefix attachment.prefix, {size: 'large'}
        aspectRatio: attachment.aspectRatio
      }

    z '.z-attachments',
      z '.g-grid',
        z '.g-cols',
          if not attachments
            z @$spinner
          else
            _map attachments, (attachment, i) =>
              src = @model.image.getSrcByPrefix attachment.prefix, {
                size: 'small'
              }
              z '.g-col.g-xs-6.g-md-3',
                z '.attachment', {
                  onclick: =>
                    @model.overlay.open new ImageViewOverlay {
                      @model
                      @router
                      images: images
                      imageIndex: i
                    }
                  oncontextmenu: (e) =>
                    if (attachment.userId is me.id or me.username is 'austin') and confirm 'Delete?'
                      e?.preventDefault()
                      @model.campgroundAttachment.deleteByRow attachment
                },
                  z '.image',
                    style:
                      backgroundImage:
                        "url(#{src})"
