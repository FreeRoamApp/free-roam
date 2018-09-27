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
  constructor: ({@model, @router, place, @overlay$}) ->
    @state = z.state
      place: place
      attachments: place.switchMap (place) =>
        unless place
          return RxObservable.of null
        @model.campgroundAttachment.getAllByParentId place.id

  render: =>
    {place, attachments} = @state.getValue()

    z '.z-place-attachments',
      z '.g-grid',
        z '.g-cols',
          _map attachments, (attachment) =>
            z '.g-col.g-xs-4.g-md-2',
              z '.attachment', {
                onclick: =>
                  @overlay$?.next new ImageViewOverlay {
                    @model
                    @router
                    @overlay$
                    imageData:
                      url: attachment.largeSrc
                      aspectRatio: attachment.aspectRatio
                  }
              },
                z '.image',
                  style:
                    backgroundImage: "url(#{attachment.smallSrc})"
