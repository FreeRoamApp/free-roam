z = require 'zorium'
_defaults = require 'lodash/defaults'
RxBehaviorSubject = require('rxjs/BehaviorSubject').BehaviorSubject

ShareMapDialog = require '../share_map_dialog'
Map = require '../map'
Spinner = require '../spinner'
colors = require '../../colors'

if window?
  require './index.styl'

module.exports = class ShareMap
  constructor: ({@model, @mapOptions, @onUpload, shareInfo}) ->
    @isLoading = new RxBehaviorSubject false
    @imagePrefix = new RxBehaviorSubject ''
    @blob = new RxBehaviorSubject null

    @$shareMapDialog = new ShareMapDialog {
      @model, @isLoading, @imagePrefix, @blob, shareInfo
    }
    @$spinner = new Spinner()

    @state = z.state {
      $map: null
    }

  share: =>
    @isLoading.next true
    @state.set {
      $map: new Map _defaults @mapOptions, {
        preserveDrawingBuffer: true
        hideLabels: true
        initialBounds: [[-156.187, 18.440], [-38.766, 55.152]]
        onContentReady: @_screenshot
      }
    }
    @model.overlay.open z @$shareMapDialog

  _screenshot: =>
    {$map} = @state.getValue()
    $map.getBlob()
    .then (blob) =>
      @model.trip.uploadImage blob
      .then (response) =>
        @onUpload response
        .then =>
          @imagePrefix.next response.prefix
          @blob.next blob
          @isLoading.next false

  render: =>
    {$map} = @state.getValue()

    # fb: 1200x628, instagram: 1080x566 (or 1080x1080)
    if $map
      widthPx = 1200
      heightPx = 628
    else
      widthPx = 0
      heightPx = 0

    z '.z-share-map', {
      style:
        width: "#{widthPx}px"
        height: "#{heightPx}px"
    },
      $map
