Environment = require '../services/environment'
RxBehaviorSubject = require('rxjs/BehaviorSubject').BehaviorSubject
require 'rxjs/add/operator/map'
uuid = require 'uuid'
_forEach = require 'lodash/forEach'

config = require '../config'

DRAWER_RIGHT_PADDING = 56
DRAWER_MAX_WIDTH = 336
GRID_WIDTH = 1280

module.exports = class Window
  constructor: ({@cookie, @experiment}) ->
    @isPaused = false

    @size = new RxBehaviorSubject @getSizeVal()
    @breakpoint = new RxBehaviorSubject @getBreakpointVal()
    @drawerWidth = new RxBehaviorSubject @getDrawerWidthVal()
    @appBarHeight = new RxBehaviorSubject @getAppBarHeightVal()
    @resumeFns = {}
    window?.addEventListener 'resize', @updateSize

  updateSize: =>
    unless @isPaused
      @size.next @getSizeVal()
      @breakpoint.next @getBreakpointVal()

  getSizeVal: =>
    resolution = @cookie.get 'resolution'
    if window?
      width = window.innerWidth
      height = window.innerHeight
    else if resolution
      arr = resolution.split 'x'
      width = arr[0]
      height = arr[1]
    else
      width = undefined
      height = 732

    {
      contentWidth:
        if window?.innerWidth >= 1280
        then Math.min GRID_WIDTH, width - DRAWER_MAX_WIDTH
        else width
      width: width
      height: height
    }

  getBreakpointVal: =>
    {width} = @getSizeVal()
    if width >= 1280
      'desktop'
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
    if width > 768 then 64 else 56

  getSize: =>
    @size

  getDrawerWidth: =>
    @drawerWidth

  getBreakpoint: =>
    @breakpoint

  getAppBarHeight: =>
    @appBarHeight

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
