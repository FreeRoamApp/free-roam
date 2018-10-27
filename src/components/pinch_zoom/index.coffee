z = require 'zorium'
_map = require 'lodash/map'
_defaults = require 'lodash/defaults'
RxBehaviorSubject = require('rxjs/BehaviorSubject').BehaviorSubject

if window?
  IScroll = require 'iscroll/build/iscroll-lite-snap-zoom.js'
  require './index.styl'

DOUBLE_TAP_MS = 300

module.exports = class PinchZoom
  constructor: (options = {}) ->
    {@onZoomStart, @onZoomed, @onUnzoomed, @transformX,
      @ignoreZoomBounds} = options
    @iScrollContainer = null
    @lastTap = 0

  afterMount: (@$$el) =>
    checkIsReady = =>
      $$container = @$$el?.querySelector('.z-pinch-zoom > .scroller')
      if $$container and $$container.clientWidth
        @initIScroll $$container
      else
        setTimeout checkIsReady, 1000

    checkIsReady()

  beforeUnmount: =>
    @iScrollContainer?.destroy()

  initIScroll: ($$container) =>
    @iScrollContainer = new IScroll $$container, {
      zoom: true
      disablePointer: true
      disableTouch: false
      scrollX: true
      scrollY: true
      bounce: false
      eventPassthrough: false # necessary for scrollY and scrollX to work
      deceleration: 0.002
      transformX: @transformX
    }

    @iScrollContainer.on 'zoomStart', =>
      @isZooming = true
      @onZoomStart?()

    @iScrollContainer.on 'zoomEnd', =>
      @isZooming = false
      if @iScrollContainer.scale > 1.01
        @onZoomed?()
      else
        @onUnzoomed?()

  render: ({$el, vDomKey}) ->

    vDomKey = "#{vDomKey}-pinch-zoom"

    z '.z-pinch-zoom', {
      key: vDomKey
      ontouchstart: =>
        dt = Date.now() - @lastTap
        @lastTap = Date.now()
        if dt < DOUBLE_TAP_MS and not @isZooming
          @lastTap = 0
          @iScrollContainer.zoom 1
          @onUnzoomed?()

    },
      z '.scroller', {
        key: vDomKey
      },
        z '.content',
          z $el
