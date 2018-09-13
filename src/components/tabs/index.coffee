z = require 'zorium'
_map = require 'lodash/map'
RxBehaviorSubject = require('rxjs/BehaviorSubject').BehaviorSubject

TabsBar = require '../../components/tabs_bar'

if window?
  IScroll = require 'iscroll/build/iscroll-lite-snap.js'
  require './index.styl'


module.exports = class Tabs
  constructor: ({@model, @selectedIndex, @isPageScrolling, hideTabBar}) ->
    @selectedIndex ?= new RxBehaviorSubject 0
    @isPageScrolling ?= new RxBehaviorSubject false
    @mountDisposable = null
    @iScrollContainer = null
    @isPaused = false
    @transformProperty = window?.getTransformProperty()

    @$tabsBar = new TabsBar {@model, @selectedIndex}

    @state = z.state
      selectedIndex: @selectedIndex
      hideTabBar: hideTabBar
      windowSize: @model.window.getSize()

  afterMount: (@$$el) =>
    checkIsReady = =>
      $$container = @$$el?.querySelector('.z-tabs > .content > .tabs-scroller')
      if $$container and $$container.clientWidth
        @initIScroll $$container
      else
        setTimeout checkIsReady, 1000

    checkIsReady()

  beforeUnmount: (keepEl = false) =>
    @mountDisposable?.unsubscribe()
    @iScrollContainer?.destroy()
    # @$$el?.removeEventListener 'touchstart', @onTouchStart
    # @$$el?.removeEventListener 'touchend', @onTouchEnd
    unless keepEl
      @$$el = null

  # onTouchStart: =>
  #   @isPageScrolling.next true
  #
  # onTouchEnd: =>
  #   @isPageScrolling.next false

  toggle: (mode) =>
    if mode is 'enable' and @isPaused
      @iScrollContainer.enable()
      @isPaused = false
    else if mode is 'disable' and not @isPaused
      @iScrollContainer.disable()
      @isPaused = true

  initIScroll: ($$container) =>
    {hideTabBar} = @state.getValue()

    @iScrollContainer = new IScroll $$container, {
      scrollX: true
      scrollY: false
      eventPassthrough: true
      bounce: false
      snap: '.iscroll-tab'
      deceleration: 0.002
    }

    # @$$el.addEventListener 'touchstart', @onTouchStart
    # @$$el.addEventListener 'touchend', @onTouchEnd

    unless hideTabBar
      @$$selector = @$$el?.querySelector '.z-tabs-bar .selector'
      updateSelectorPosition = =>
        # updating state and re-rendering every time is way too slow
        xOffset = -100 * @iScrollContainer.pages.length * (
          @iScrollContainer.x / @iScrollContainer.scrollerWidth
        )
        xOffset = "#{xOffset}%"
        @$$selector?.style[@transformProperty] = "translateX(#{xOffset})"

    # the scroll listener in IScroll (iscroll-probe.js) is really slow
    isScrolling = false
    @iScrollContainer.on 'scrollStart', =>
      isScrolling = true
      # @isPageScrolling.next true
      unless hideTabBar
        @$$selector = document.querySelector '.z-tabs-bar .selector'
        update = ->
          updateSelectorPosition()
          if isScrolling
            window.requestAnimationFrame update
        update()
        updateSelectorPosition()

    @iScrollContainer.on 'scrollEnd', =>
      {selectedIndex} = @state.getValue()
      isScrolling = false
      # causes extra render
      # @isPageScrolling.next false

      newIndex = @iScrollContainer.currentPage.pageX
      # landing on new tab
      if selectedIndex isnt newIndex
        @selectedIndex.next newIndex

    @mountDisposable = @selectedIndex.do((index) =>
      if @iScrollContainer.pages?[index]
        @iScrollContainer.goToPage index, 0, 500
      unless hideTabBar
        @$$selector = document.querySelector '.z-tabs-bar .selector'
        updateSelectorPosition()
    ).subscribe()

  render: (options) =>
    {tabs, barColor, barBgColor, barInactiveColor, isBarFixed, isBarFlat,
      barTabWidth, hasAppBar, windowSize, vDomKey, barStyle} = options

    tabs ?= [{$el: ''}]
    x = @iScrollContainer?.x

    # if @lastTabsLength and tabs?.length and @lastTabsLength isnt tabs?.length
    #   @beforeUnmount true
    #   setTimeout =>
    #     @afterMount @$$el
    #   , 100
    # @lastTabsLength = tabs?.length

    {selectedIndex, hideTabBar, windowSize} = @state.getValue()

    vDomKey = "#{vDomKey}-tabs-#{tabs?.length}"
    isBarFixed ?= true
    isBarFlat ?= true

    z '.z-tabs', {
      className: z.classKebab {isBarFixed}
      key: vDomKey
      style:
        maxWidth: "#{windowSize.width}px"
    },
      z '.content',
        unless hideTabBar
          z '.tabs-bar',
            z @$tabsBar, {
              isFixed: isBarFixed
              isFlat: isBarFlat
              tabWidth: barTabWidth
              color: barColor
              inactiveColor: barInactiveColor
              bgColor: barBgColor
              style: barStyle
              items: tabs
            }
        z '.tabs-scroller', {
          key: vDomKey
        },
          z '.tabs', {
            style:
              minWidth: "#{(100 * tabs.length)}%"
              # v-dom sometimes changes up the DOM node we're using when the
              # page changes, then back to this page. when that happens,
              # translate x is 0 initially even though iscroll might realize
              # it's actually something other than 0. since iscroll uses
              # css transitions, it causes the page to swipe in, which looks bad
              # This fixes that
              "#{@transformProperty}": "translate(#{x}px, 0px) translateZ(0px)"
              # webkitTransform: "translate(#{x}px, 0px) translateZ(0px)"
          },
            _map tabs, ({$el}, i) ->
              z '.iscroll-tab', {
                style:
                  width: "#{(100 / tabs.length)}%"
              },
                $el
