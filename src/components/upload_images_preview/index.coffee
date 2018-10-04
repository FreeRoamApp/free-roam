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
    {@multiImageData, @model, @overlay$,
      @onUpload, @onUploading, @onProgress, @uploadFn} = options

    @$appBar = new AppBar {@model}

    @step = new RxBehaviorSubject 0
    @$stepBar = new StepBar {@model, @step}

    multiImageData = @multiImageData.map (multiImageData) =>
      _map multiImageData, (imageData) =>
        captionValueSubject = new RxBehaviorSubject ''
        tagValueSubject = new RxBehaviorSubject ''
        hasLocationValueSubject = new RxBehaviorSubject true
        locationValueSubject = new RxBehaviorSubject null
        @getLocation imageData.file, locationValueSubject
        {
          imageData
          captionValueSubject
          tagValueSubject
          hasLocationValueSubject
          locationValueSubject
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
      tags: tags


  getLocation: (file, locationValueSubject) =>
    @model.additionalScript.add(
      'js', 'https://fdn.uno/d/scripts/exif-parser.min.js'
    ).then ->
      reader = new FileReader()
      reader.onload = (e) ->
        parser = window.ExifParser.create(e.target.result)
        parser.enableSimpleValues true
        result = parser.parse()
        location = if result.tags.GPSLatitude \
                   then [result.tags.GPSLatitude, result.tags.GPSLongitude]
                   else null
        locationValueSubject.next location
      reader.readAsArrayBuffer file

  afterMount: =>
    @disposable = @location.subscribe (location) =>
      if location?[0]
        @places.next [{
          location:
            lat: location[0]
            lon: location[1]
        }]
        @mapCenter.next [location[1], location[0]]

  beforeUnmount: =>
    @disposable?.unsubscribe()
    @step.next 0

  render: =>
    {multiImageData, imageIndex, location, tags,
      isLoading, windowSize} = @state.getValue()

    console.log 'tags', tags

    {imageData, $captionInput, $tagInput, $tagButton, $includeLocationCheckbox
      tagValueSubject, tagsValueSubject} = multiImageData?[imageIndex] or {}
    imageData ?= {}

    if imageData.width
      imageAspectRatio = imageData.width / imageData.height
      windowAspectRatio = windowSize.width / windowSize.height
      # 3:1, 1:1
      if imageAspectRatio > windowAspectRatio
        previewWidth = Math.min windowSize.width, imageData.width
        previewHeight = previewWidth / imageAspectRatio
      else
        previewHeight = Math.min windowSize.height, imageData.height
        previewWidth = previewHeight * imageAspectRatio
    else
      previewHeight = undefined
      previewWidth = undefined

    z '.z-upload-images-preview',
      z @$appBar,
        title: @model.l.get 'uploadImagesOverlay.title'
      z '.g-grid',
        z '.caption', {key: "upload-images-caption-#{imageIndex}"},
          z $captionInput,
            hintText: @model.l.get 'uploadImagesOverlay.captionHintText'
        z 'img',
          src: imageData.dataUrl
          width: previewWidth
          height: previewHeight
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
        z '.location', {
          className: z.classKebab {
            isVisible: Boolean location?[0]
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
            @overlay$.next null
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
                  console.log 'onprogress', response
                  @onProgress response, {clientId}
              }
              .then (response) =>
                @onUpload(
                  _defaults(response, {caption, location, tags})
                  {clientId}
                )
            @multiImageData.next null
            @overlay$.next null
      }
