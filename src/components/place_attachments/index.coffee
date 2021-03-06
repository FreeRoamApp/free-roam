z = require 'zorium'
RxObservable = require('rxjs/Observable').Observable
require 'rxjs/add/observable/of'

Attachments = require '../attachments'
colors = require '../../colors'
config = require '../../config'

if window?
  require './index.styl'

module.exports = class PlaceAttachments
  constructor: ({@model, @router, place}) ->
    attachments = place.switchMap (place) =>
      unless place?.id
        return RxObservable.of null
      @placeAttachmentModel.getAllByParentId place.id

    @$attachments = new Attachments {
      @model, @router, attachments, parent: place
    }

    @state = z.state {place}

  render: =>
    {place} = @state.getValue()

    z '.z-place-attachments',
      z @$attachments
