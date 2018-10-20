z = require 'zorium'
_map = require 'lodash/map'
RxObservable = require('rxjs/Observable').Observable
require 'rxjs/add/observable/of'

ImageViewOverlay = require '../image_view_overlay'
colors = require '../../colors'
config = require '../../config'

if window?
  require './index.styl'

module.exports = class PlaceAttachments
  constructor: ({@model, @router, place}) ->
    @state = z.state
      me: @model.user.getMe()
      place: place
      attachments: place.switchMap (place) =>
        unless place
          return RxObservable.of null
        @model.campgroundAttachment.getAllByParentId place.id

  render: =>
    {me, place, attachments} = @state.getValue()

    z '.z-place-attachments',
      z '.g-grid',
        z '.g-cols',
          _map attachments, (attachment) =>
            z '.g-col.g-xs-4.g-md-2',
              z '.attachment', {
                onclick: =>
                  @model.overlay.open new ImageViewOverlay {
                    @model
                    @router
                    imageData:
                      url: attachment.largeSrc
                      aspectRatio: attachment.aspectRatio
                  }
                # FIXME: rm after 10/31/2018, or just enable for austin
                oncontextmenu: (e) =>
                  if (attachment.userId is me.id or me.username is 'austin') and confirm 'Delete?'
                    e?.preventDefault()
                    @model.campgroundAttachment.deleteByRow attachment
              },
                z '.image',
                  style:
                    backgroundImage: "url(#{attachment.smallSrc})"
