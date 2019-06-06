z = require 'zorium'
RxBehaviorSubject = require('rxjs/BehaviorSubject').BehaviorSubject
_map = require 'lodash/map'
_filter = require 'lodash/filter'

Icon = require '../icon'
ButtonBack = require '../button_back'
AppBar = require '../app_bar'
PinchZoom = require '../pinch_zoom'
Tabs = require '../tabs'
colors = require '../../colors'
config = require '../../config'

if window?
  require './index.styl'

module.exports = class ImageViewOverlay
  constructor: ({@model, @router, imageData, images, imageIndex}) ->
    @$buttonBack = new ButtonBack {@router}
    @$appBar = new AppBar {@model}

    @selectedIndex = new RxBehaviorSubject 1 # start in middle of 0 1 2
    @imageIndex = new RxBehaviorSubject imageIndex or 0
    @$tabs = new Tabs {
      @model, @selectedIndex, hideTabBar: true, disableDeceleration: true
    }
    @$previousIcon = new Icon()
    @$nextIcon = new Icon()
    @$pinchZoom = new PinchZoom {
      onZoomStart: =>
        @$tabs.toggle 'disable'
      onZoomed: =>
        @$tabs.toggle 'disable'
      onUnzoomed: =>
        setTimeout =>
          @$tabs.toggle 'enable'
        , 0
      # account for being middle slide
      # WARNING: causes reflows, so don't call this too often
      transformX: if images?.length > 1 then window.innerWidth else 0
    }

    @state = z.state
      imageData: imageData
      images: images
      selectedIndex: @selectedIndex
      imageIndex: @imageIndex
      windowSize: @model.window.getSize()
      appBarHeight: @model.window.getAppBarHeight()

  afterMount: (@$$el) =>
    $$tabs = @$$el.querySelector('.tabs')

    @preloadedImageIndices = [0]

    @mountDisposable1 = @imageIndex.subscribe (imageIndex) =>
      {images} = @state.getValue()

      imageCount = images?.length or 0
      # preload next 2 and prev 2 images
      prev1 = imageIndex - 1
      if prev1 < 0
        prev1 = images?.length - 1
      prev2 = imageIndex - 2
      if prev2 < 0
        prev2 = images?.length - 2
      toPreload = [
        (imageIndex + 1) % (imageCount)
        (imageIndex + 2) % (imageCount)
        prev1
        prev2
      ].slice(0, imageCount - 1)
      toPreload = _filter toPreload, (index) =>
        @preloadedImageIndices.indexOf(index) is -1
      @preloadedImageIndices = @preloadedImageIndices.concat toPreload
      _map toPreload, (preloadIndex) ->
        img = new Image()
        img.src = images[preloadIndex]?.url
      # @preloadedImageIndices


    @mountDisposable2 = @selectedIndex.do((index) =>
      {images, imageIndex} = @state.getValue()

      imageCount = images?.length or 0
      if index is 2
        imageIndex = imageIndex += 1
        if imageIndex >= images?.length
          imageIndex = 0
        setTimeout =>
          @$tabs.disableTransition()
          @selectedIndex.next 1
          @imageIndex.next imageIndex
          setTimeout =>
            @$tabs.enableTransition()
          , 0
        , 0
      else if index is 0
        imageIndex = imageIndex -= 1
        if imageIndex < 0
          imageIndex = images?.length - 1
      if index in [0, 2]
        setTimeout =>
          @$tabs.disableTransition()
          @selectedIndex.next 1
          @imageIndex.next imageIndex
          setTimeout =>
            @$tabs.enableTransition()
          , 0
        , 0
    ).subscribe()

  beforeUnmount: =>
    @preloadedImageIndices = []
    @mountDisposable1?.unsubscribe()
    @mountDisposable2?.unsubscribe()

  getDimensions: (aspectRatio) =>
    {windowSize, appBarHeight} = @state.getValue()

    windowHeight = windowSize.height - appBarHeight

    if aspectRatio
      imageAspectRatio = aspectRatio
      windowAspectRatio = windowSize.width / windowHeight

      if imageAspectRatio > windowAspectRatio
        width = windowSize.width
        height = width / imageAspectRatio
      else
        height = windowHeight
        width = height * imageAspectRatio
    else
      height = undefined
      width = undefined

    {width, height}

  render: =>
    {windowSize, appBarHeight, imageData,
      images, selectedIndex, imageIndex} = @state.getValue()

    images ?= [imageData]

    prevIndex = imageIndex - 1
    if prevIndex < 0
      prevIndex = images?.length - 1

    nextIndex = imageIndex + 1
    if nextIndex >= images?.length
      nextIndex = 0

    image0 = images?[prevIndex]
    image1 = images?[imageIndex]
    image2 = images?[nextIndex]

    dimensions0 = @getDimensions image0?.aspectRatio
    dimensions1 = @getDimensions image1?.aspectRatio
    dimensions2 = @getDimensions image2?.aspectRatio

    z '.z-image-view-overlay',
      z @$appBar, {
        title: if images?.length > 1 \
               then @model.l.get 'general.images'
               else @model.l.get 'general.image'
        $topLeftButton: z @$buttonBack, {
          color: colors.$header500Icon
          onclick: =>
            @model.overlay.close()
        }
      }
      if images?.length is 1
        z @$pinchZoom,
          $el:
            z 'img.z-image-view-overlay_image',
              src: image1?.url
              width: dimensions1.width
              height: dimensions1.height
      else
        [
          z '.previous',
            z @$previousIcon,
              icon: 'chevron-left'
              onclick: =>
                @imageIndex.next prevIndex
              color: colors.$white54
          z '.next',
            z @$nextIcon,
              icon: 'chevron-right'
              onclick: =>
                @imageIndex.next nextIndex
              color: colors.$white54
          z '.slider',
            z @$tabs,
              isBarFixed: false
              tabs: [
                {
                  $el:
                    z 'img.z-image-view-overlay_image',
                      src: image0?.url
                      width: dimensions0.width
                      height: dimensions0.height
                }
                {
                  $el:
                    z @$pinchZoom,
                      $el:
                        z 'img.z-image-view-overlay_image',
                          src: image1?.url
                          width: dimensions1.width
                          height: dimensions1.height
                }
                {
                  $el:
                    z 'img.z-image-view-overlay_image',
                      src: image2?.url
                      width: dimensions2.width
                      height: dimensions2.height
                }
              ]
        ]
