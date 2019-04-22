z = require 'zorium'
RxBehaviorSubject = require('rxjs/BehaviorSubject').BehaviorSubject
RxObservable = require('rxjs/Observable').Observable
require 'rxjs/add/observable/combineLatest'
require 'rxjs/add/observable/of'
uuid = require 'uuid'
_map = require 'lodash/map'
_defaults = require 'lodash/defaults'
_uniq = require 'lodash/uniq'

AppBar = require '../app_bar'
Checkbox = require '../checkbox'
StepBar = require '../step_bar'
PrimaryInput = require '../primary_input'
PrimaryButton = require '../primary_button'
Icon = require '../icon'
Map = require '../map'
Fab = require '../fab'
colors = require '../../colors'
config = require '../../config'

if window?
  require './index.styl'

###
- let use select multiple to upload
- while they're uploading, let them specify titles
- once titles are specified, continue uploading in background like inbox
###

module.exports = class UploadImagesPreview
  constructor: (options) ->
    {@multiImageData, @model, @requestTags, @requestLocation,
      @onUpload, @onUploading, @onProgress, @uploadFn} = options

    @requestTags ?= true
    @requestLocation ?= true

    @$appBar = new AppBar {@model}

    @step = new RxBehaviorSubject 0
    @$stepBar = new StepBar {@model, @step}

    multiImageData = @multiImageData.map (multiImageData) =>
      _map multiImageData, (imageData) =>
        captionValueSubject = new RxBehaviorSubject ''
        tagValueSubject = new RxBehaviorSubject ''
        hasLocationValueSubject = new RxBehaviorSubject true
        locationValueSubject = new RxBehaviorSubject null
        rotationValueSubject = new RxBehaviorSubject null
        @model.image.parseExif(
          imageData.file, locationValueSubject, rotationValueSubject
        )
        {
          imageData
          captionValueSubject
          tagValueSubject
          hasLocationValueSubject
          locationValueSubject
          rotationValueSubject
          tagsValueSubject: new RxBehaviorSubject []
          $captionInput: new PrimaryInput {value: captionValueSubject}
          $tagInput: new PrimaryInput {value: tagValueSubject}
          $tagButton: new PrimaryButton()
          $includeLocationCheckbox: new Checkbox {
            value: hasLocationValueSubject
          }
        }
    .publishReplay(1).refCount()

    stepAndMultiImageData = RxObservable.combineLatest(
      @step, multiImageData, (vals...) -> vals
    )
    @location = stepAndMultiImageData.switchMap ([step, multiImageData]) ->
      multiImageData[step]?.locationValueSubject or RxObservable.of null
    .publishReplay(1).refCount()
    @rotation = stepAndMultiImageData.switchMap ([step, multiImageData]) ->
      multiImageData[step]?.rotationValueSubject or RxObservable.of null
    .publishReplay(1).refCount()

    tags = stepAndMultiImageData.switchMap ([step, multiImageData]) ->
      multiImageData[step]?.tagsValueSubject or RxObservable.of null

    @places = new RxBehaviorSubject []
    @mapCenter = new RxBehaviorSubject null

    @$map = new Map {
      @model, @router, @places, center: @mapCenter, initialZoom: 11
    }

    @state = z.state
      imageIndex: @step
      multiImageData: multiImageData
      isLoading: false
      windowSize: @model.window.getSize()
      location: @location
      rotation: @rotation
      tags: tags


  parseExif: (file, locationValueSubject, rotationValueSubject) =>
    @model.additionalScript.add(
      'js', 'https://fdn.uno/d/scripts/exif-parser.min.js'
    ).then ->
      reader = new FileReader()
      reader.onload = (e) ->
        parser = window.ExifParser.create(e.target.result)
        parser.enableSimpleValues true
        result = parser.parse()
        rotation = switch result.tags.Orientation
                        when 3 then 'rotate-180'
                        when 8 then 'rotate-90'
                        when 6 then 'rotate-270'
                        else ''
        location = if result.tags.GPSLatitude \
                   then {lat: result.tags.GPSLatitude, lon: result.tags.GPSLongitude}
                   else null
        rotationValueSubject.next rotation
        locationValueSubject.next location
      reader.readAsArrayBuffer file

  afterMount: =>
    @disposable = @location.subscribe (location) =>
      if location?.lon
        @places.next [{
          location: location
        }]
        @mapCenter.next [location.lon, location.lat]

  beforeUnmount: =>
    @disposable?.unsubscribe()
    @step.next 0

  render: =>
    {multiImageData, imageIndex, location, rotation, tags,
      isLoading, windowSize} = @state.getValue()

    {imageData, $captionInput, $tagInput, $tagButton, $includeLocationCheckbox
      tagValueSubject, tagsValueSubject} = multiImageData?[imageIndex] or {}
    imageData ?= {}

    maxWidth = Math.min windowSize.width, 600

    if imageData.width
      imageAspectRatio = imageData.width / imageData.height
      windowAspectRatio = maxWidth / windowSize.height
      # 3:1, 1:1
      if imageAspectRatio > windowAspectRatio
        previewWidth = Math.min maxWidth, imageData.width
        previewHeight = previewWidth / imageAspectRatio
      else
        previewHeight = Math.min windowSize.height, imageData.height
        previewWidth = previewHeight * imageAspectRatio
    else
      previewHeight = undefined
      previewWidth = undefined

    isRotated = rotation in ['rotate-90', 'rotate-270']

    z '.z-upload-images-preview',
      z @$appBar,
        title: @model.l.get 'uploadImagesOverlay.title'
      z '.g-grid',
        z '.caption', {key: "upload-images-caption-#{imageIndex}"},
          z $captionInput,
            hintText: @model.l.get 'uploadImagesOverlay.captionHintText'
        z ".image-wrapper.#{rotation or 'no-rotation'}", {
          style:
            height: if isRotated \
                    then "#{previewWidth + 50}px"
                    else "#{previewHeight + 50}px"
            # width: if isRotated \
            #         then "#{previewHeight}px"
            #         else "#{previewWidth}px"
        },
          z "img",
            src: imageData.dataUrl
            width: previewWidth
            height: previewHeight
            style:
              marginTop: if isRotated \
                         then "#{50 + (previewWidth - previewHeight) / 2}px"
                         else '50px'
              marginLeft: if isRotated \
                         then "#{(previewHeight - previewWidth) / 2}px"
                         else 0
        if @requestTags
          z '.tags', {key: "upload-images-tags-#{imageIndex}"},
            z '.input',
              z $tagInput,
                hintText: @model.l.get 'uploadImagesOverlay.tagHintText'
            z '.button',
              z $tagButton,
                text: @model.l.get 'uploadImagesOverlay.addTag'
                onclick: ->
                  existingTags = tagsValueSubject.getValue()
                  newTag = tagValueSubject.getValue()
                           .trim().toLowerCase().replace '#', ''
                  tagsValueSubject.next _uniq existingTags.concat [newTag]
                  tagValueSubject.next ''
            z '.tags',
              _map tags, (tag) ->
                z '.tag', "##{tag}"
        if @requestLocation
          z '.location', {
            className: z.classKebab {
              isVisible: Boolean location?.lon
            }
          },
            z '.include-location',
              z 'label',
                z '.checkbox',
                  z $includeLocationCheckbox
                @model.l.get 'uploadImagesOverlay.includeLocation'
            z '.map',
              z @$map

      z @$stepBar, {
        isSaving: false
        steps: multiImageData?.length
        isStepCompleted: true
        cancel:
          onclick: =>
            @multiImageData.next null
            @model.overlay.close()
        # TODO: trash icon?
        save:
          icon: 'arrow-right'
          onclick: (e) =>
            _map multiImageData, (data) =>
              {imageData, captionValueSubject, hasLocationValueSubject,
                locationValueSubject} = data

              clientId = uuid.v4()
              caption = captionValueSubject.getValue()
              tags = tagsValueSubject.getValue()
              location = if hasLocationValueSubject.getValue() \
                         then locationValueSubject.getValue()
                         else undefined

              @onUploading imageData.dataUrl, {clientId}
              @uploadFn imageData.file, {
                onProgress: (response) =>
                  @onProgress response, {clientId}
              }
              .then (response) =>
                attachment = _defaults(response, {caption})
                if @requestLocation
                  attachment.location = location
                if @requestTags
                  attachment.tags = tags
                @onUpload(
                  attachment
                  {clientId}
                )
            @multiImageData.next null
            @model.overlay.close()
      }
