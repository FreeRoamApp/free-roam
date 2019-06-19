RxBehaviorSubject = require('rxjs/BehaviorSubject').BehaviorSubject
require 'rxjs/add/operator/map'
_forEach = require 'lodash/forEach'
if window?
  uuid = require 'uuid'

DRAWER_RIGHT_PADDING = 56
DRAWER_MAX_WIDTH = 336
GRID_WIDTH = 1280

module.exports = class Window
  constructor: ({@cookie, @experiment, @userAgent}) ->
    @isPaused = false

    @size = new RxBehaviorSubject @getSizeVal()
    @breakpoint = new RxBehaviorSubject @getBreakpointVal()
    @drawerWidth = new RxBehaviorSubject @getDrawerWidthVal()
    @appBarHeight = new RxBehaviorSubject @getAppBarHeightVal()
    @resumeFns = {}
    window?.addEventListener 'resize', @updateSize

  updateSize: (ignoreBreakpoint) =>
    oldSize = @size.getValue()
    newSize = @getSizeVal()
    oldBreakpoint = @breakpoint.getValue()
    newBreakpoint = @getBreakpointVal()
    # don't want to update if not necessary. particularly because there can be
    # breakpoint-specific routes in app.coffee, and those listen to @breakpoint
    unless @isPaused
      if oldSize isnt newSize
        @size.next newSize
      if oldBreakpoint isnt newBreakpoint
        @breakpoint.next newBreakpoint

  getSizeVal: =>
    resolution = @cookie.get 'resolution'
    if window?
      # WARNING: causes reflows, so don't call this too often
      width = window.innerWidth
      height = window.innerHeight
      @cookie.set('resolution', "#{width}x#{height}")
    else if resolution
      arr = resolution.split 'x'
      width = parseInt arr[0]
      height = parseInt arr[1]
    else
      width = undefined
      height = 732

    {
      contentWidth:
        if width >= 1280
        then Math.min GRID_WIDTH, width - DRAWER_MAX_WIDTH
        else width
      width: width
      height: height
      appBarHeight: if width >= 768 then 64 else 56
    }

  getBreakpointVal: =>
    {width} = @getSizeVal()
    if width >= 1280
      'desktop'
    else if width >= 768
      'tablet'
    else
      'mobile'

  getDrawerWidthVal: =>
    {width} = @getSizeVal()
    Math.min(
      width - DRAWER_RIGHT_PADDING
      DRAWER_MAX_WIDTH
    )

  getAppBarHeightVal: =>
    {width} = @getSizeVal()
    if width >= 768 then 64 else 56

  getUserAgent: =>
    @userAgent

  getSize: =>
    @size

  getDrawerWidth: =>
    @drawerWidth

  getBreakpoint: =>
    @breakpoint

  getAppBarHeight: =>
    @appBarHeight

  getTransformProperty: ->
    if window?
      _elementStyle = document.createElement('div').style
      _vendor = do ->
        vendors = [
          't'
          'webkitT'
          'MozT'
          'msT'
          'OT'
        ]
        transform = undefined
        i = 0
        l = vendors.length
        while i < l
          transform = vendors[i] + 'ransform'
          if transform of _elementStyle
            return vendors[i].substr(0, vendors[i].length - 1)
          i += 1
        false

      _prefixStyle = (style) ->
        if _vendor is false
          return false
        if _vendor is ''
          return style
        _vendor + style.charAt(0).toUpperCase() + style.substr(1)

      _prefixStyle 'transform'
    else
      'transform' # should probably use userAgent to get more accurate

  pauseResizing: =>
    @isPaused = true

  resumeResizing: =>
    @isPaused = false
    @updateSize()

  resume: =>
    _forEach @resumeFns, (fn) ->
      fn()

  onResume: (fn) =>
    id = uuid.v4()
    @resumeFns[id] = fn
    unsubscribe: =>
      delete @resumeFns[id]
