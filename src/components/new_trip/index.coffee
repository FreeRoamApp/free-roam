z = require 'zorium'
RxBehaviorSubject = require('rxjs/BehaviorSubject').BehaviorSubject
RxReplaySubject = require('rxjs/ReplaySubject').ReplaySubject
RxObservable = require('rxjs/Observable').Observable
require 'rxjs/add/observable/of'
_filter = require 'lodash/filter'
_map = require 'lodash/map'
_range = require 'lodash/range'

PrimaryInput = require '../primary_input'
SecondaryButton = require '../secondary_button'
UploadOverlay = require '../upload_overlay'
Icon = require '../icon'
colors = require '../../colors'
config = require '../../config'

if window?
  require './index.styl'

module.exports = class NewTrip
  constructor: ({@model, @router, @trip}) ->
    me = @model.user.getMe()

    @fields =
      name:
        valueStreams: new RxReplaySubject 1
        errorSubject: new RxBehaviorSubject null
      thumbnailPrefix:
        valueStreams: new RxReplaySubject 1
        errorSubject: new RxBehaviorSubject null

    @resetValueStreams()

    @$nameInput = new PrimaryInput
      valueStreams: @fields.name.valueStreams
      error: @fields.errorSubject

    @thumbnailImage = new RxBehaviorSubject null
    rotationValueSubject = new RxBehaviorSubject null
    @$uploadOverlay = new UploadOverlay {@model}
    @$editIcon = new Icon()
    @$uploadIcon = new Icon()

    @$saveButton = new SecondaryButton()

    @state = z.state {
      isLoading: false
      trip: @trip
      nameValue: @fields.name.valueStreams.switch()
      imageIndex: 0
      thumbnailRotation: rotationValueSubject
      thumbnailDataUrl: null
      thumbnailImage: @thumbnailImage.map (file) =>
        if file
          @model.image.parseExif(
            file, null, rotationValueSubject
          )
        file
    }

  resetValueStreams: =>
    if @trip
      @fields.name.valueStreams.next @trip.map (trip) ->
        trip?.name or ''
    else
      @fields.name.valueStreams.next RxObservable.of ''


  upsert: (e) =>
    {trip, isLoading, nameValue, imageIndex, thumbnailImage} = @state.getValue()

    unless isLoading
      @state.set isLoading: true
      @fields.name.errorSubject.next null

      @model.trip.upsert {
        type: trip?.type or 'custom'
        id: trip?.id
        name: nameValue
        thumbnailPrefix: if imageIndex isnt 5
          "trips/preset_#{imageIndex + 1}"
      }, {file: if imageIndex is 5 then thumbnailImage else null}
      .then (trip) =>
        @state.set {isLoading: false}
        @thumbnailImage.next null
        @resetValueStreams()
        # FIXME FIXME
        setTimeout =>
          @router.go 'trip', {
            id: trip.id
          }, {reset: true}
        , 200
      .catch (err) =>
        console.log err
        err = try
          JSON.parse err.message
        catch
          {}
        errorSubject = switch err.info?.field
          when 'name' then @fields.name.errorSubject
          else @fields.name.errorSubject
        errorSubject.next err.info?.message or 'Error'

        @state.set isLoading: false

  render: =>
    {isLoading, imageIndex, thumbnailUploadError
      thumbnailDataUrl, thumbnailRotation} = @state.getValue()

    z '.z-new-trip',
      z '.g-grid',
        z 'label.field',
          z @$nameInput,
            hintText: @model.l.get 'newTrip.title'

        z '.title',
          @model.l.get 'newTrip.thumbnail'
        z '.photos.g-grid',
          z '.g-cols',
            [
              _map _range(5), (i) =>
                z '.g-col.g-xs-4.g-md-2',
                  z '.photo',
                    className: z.classKebab {isSelected: imageIndex is i}
                    onclick: =>
                      @state.set {imageIndex: i}
                    style:
                      backgroundImage: "url(#{config.CDN_URL}/trips/preset_#{i + 1}.jpg)"

              z '.g-col.g-xs-4.g-md-2',
                z '.photo.upload', {
                  style:
                    backgroundImage: if thumbnailDataUrl
                      "url(#{thumbnailDataUrl})"
                  onclick: =>
                    @state.set {imageIndex: 5}
                  className:
                    z.classKebab {
                      "#{thumbnailRotation}": true
                      isSelected: imageIndex is 5
                    }

                },
                  z @$uploadIcon,
                    icon: 'upload'
                    isTouchTarget: false
                    color: colors.$bgText54
                  if thumbnailDataUrl
                    z '.edit',
                      z @$editIcon,
                        icon: 'edit'
                        isTouchTarget: false
                        color: colors.$secondary500
                        size: '18px'
                      z '.upload-overlay',
                        z @$uploadOverlay,
                          onSelect: ({file, dataUrl}) =>
                            @thumbnailImage.next file
                            @state.set thumbnailDataUrl: dataUrl
                  else
                    z '.upload-overlay',
                      z @$uploadOverlay,
                        onSelect: ({file, dataUrl}) =>
                          @thumbnailImage.next file
                          @state.set thumbnailDataUrl: dataUrl
            ]

        z '.actions',
          z @$saveButton,
            text: if isLoading \
                  then @model.l.get 'general.loading'
                  else if @trip
                  then @model.l.get 'general.save'
                  else @model.l.get 'general.create'
            onclick: @upsert
