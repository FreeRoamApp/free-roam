z = require 'zorium'

colors = require '../../colors'
config = require '../../config'

if window?
  IScroll = require 'iscroll/build/iscroll-lite-snap.js'
  require './index.styl'

MAX_OVERLAY_OPACITY = 0.5

module.exports = class Drawer
  constructor: ({@model, @isOpen, @onOpen, @onClose, @side, @key, @isStatic}) ->
    @transformProperty = window?.getTransformProperty()

    @side ?= 'left'
    @key ?= 'nav'
    @isStatic ?= @model.window.getBreakpoint().map (breakpoint) ->
      breakpoint in ['desktop']
    .publishReplay(1).refCount()

    @state = z.state
      isOpen: @isOpen
      isStatic: @isStatic
      windowSize: @model.window.getSize()
      appBarHeight: @model.window.getAppBarHeightVal()
      drawerWidth: @model.window.getDrawerWidth()

  afterMount: (@$$el) =>
    {drawerWidth} = @state.getValue()

    onStaticChange = (isStatic) =>
      if not @iScrollContainer and not isStatic
        checkIsReady = =>
          $$container = @$$el
          if $$container and $$container.clientWidth
            setImmediate =># sometimes get cannot get length of undefined for gotopage with this
              @initIScroll $$container
          else
            setTimeout checkIsReady, 1000

        checkIsReady()
      else if @iScrollContainer and isStatic
        @open 0
        @iScrollContainer?.destroy()
        delete @iScrollContainer
        @disposable?.unsubscribe()
    @isStaticDisposable = @isStatic.subscribe onStaticChange

  beforeUnmount: =>
    @iScrollContainer?.destroy()
    delete @iScrollContainer
    @disposable?.unsubscribe()
    @isStaticDisposable?.unsubscribe()

  close: (animationLengthMs = 500) =>
    try
      if @side is 'right'
        @iScrollContainer.goToPage 0, 0, animationLengthMs
      else
        @iScrollContainer.goToPage 1, 0, animationLengthMs
    catch err
      console.log 'caught err', err

  open: (animationLengthMs = 500) =>
    try
      if @side is 'right'
        @iScrollContainer.goToPage 1, 0, animationLengthMs
      else
        @iScrollContainer.goToPage 0, 0, animationLengthMs
    catch err
      console.log 'caught err', err

  initIScroll: ($$container) =>
    {drawerWidth} = @state.getValue()
    @iScrollContainer = new IScroll $$container, {
      scrollX: true
      scrollY: false
      eventPassthrough: true
      bounce: false
      snap: '.tab'
      deceleration: 0.002
    }

    # the scroll listener in IScroll (iscroll-probe.js) is really slow
    updateOpacity = =>
      if @side is 'right'
        opacity = -1 * @iScrollContainer.x / drawerWidth
      else
        opacity = 1 + @iScrollContainer.x / drawerWidth

      @$$overlay.style.opacity = opacity * MAX_OVERLAY_OPACITY

    @disposable = @isOpen.subscribe (isOpen) =>
      if isOpen then @open() else @close()
      @$$overlay = @$$el.querySelector '.overlay-tab'
      updateOpacity()

    isScrolling = false
    @iScrollContainer.on 'scrollStart', =>
      isScrolling = true
      @$$overlay = @$$el.querySelector '.overlay-tab'
      update = ->
        updateOpacity()
        if isScrolling
          window.requestAnimationFrame update
      update()
      updateOpacity()

    @iScrollContainer.on 'scrollEnd', =>
      {isOpen} = @state.getValue()
      isScrolling = false

      openPage = if @side is 'right' then 1 else 0

      newIsOpen = @iScrollContainer.currentPage.pageX is openPage

      # landing on new tab
      if newIsOpen and not isOpen
        @onOpen()
      else if not newIsOpen and isOpen
        @onClose()

  render: ({$content, hasAppBar}) =>
    {isOpen, windowSize, appBarHeight,
      drawerWidth, isStatic} = @state.getValue()

    height = windowSize.height
    if hasAppBar and isStatic
      height -= appBarHeight

    $drawerTab =
      z '.drawer-tab.tab',
        z '.drawer', {
          style:
            width: "#{drawerWidth}px"
        },
          $content

    $overlayTab =
      z '.overlay-tab.tab', {
        onclick: =>
          @onClose()
      },
        z '.grip'

    z '.z-drawer', {
      className: z.classKebab {isOpen, isStatic, isRight: @side is 'right'}
      key: "drawer-#{@key}"
      style:
        display: if windowSize.width then 'block' else 'none'
        height: "#{height}px"
        width: if not isStatic \
               then '100%'
               else "#{drawerWidth}px"
    },
      z '.drawer-wrapper', {
        style:
          width: "#{drawerWidth + windowSize.width}px"
          # "#{@transformProperty}": "translate(#{translateX}, 0)"
          # webkitTransform: "translate(#{translateX}, 0)"
      },
        if @side is 'right'
          [$overlayTab, $drawerTab]
        else
          [$drawerTab, $overlayTab]
