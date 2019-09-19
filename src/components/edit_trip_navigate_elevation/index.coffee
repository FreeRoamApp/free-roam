z = require 'zorium'
RxBehaviorSubject = require('rxjs/BehaviorSubject').BehaviorSubject
RxObservable = require('rxjs/Observable').Observable
require 'rxjs/add/observable/combineLatest'

ElevationChart = require '../elevation_chart'
Icon = require '../icon'
colors = require '../../colors'
config = require '../../config'

if window?
  require './index.styl'

module.exports = class EditTripNavigateElevation
  constructor: ({@model, routes}) ->
    @$mainGainIcon = new Icon()
    @$mainLostIcon = new Icon()
    @$altGainIcon = new Icon()
    @$altLostIcon = new Icon()

    @$elevationChart = new ElevationChart {
      @model
      routes
      size: @model.window.getSize().map ({width}) ->
        {width}
    }

    @state = z.state {
      routes
    }

  render: =>
    {routes} = @state.getValue()

    mainRoute = routes?[0]
    altRoute = routes?[1]

    z '.z-edit-trip-navigate-elevation',
      z '.elevations',
        z '.main',
          z '.icon',
            z @$mainGainIcon,
              icon: 'arrow-up'
              isTouchTarget: false
              color: colors.$secondary500
          z '.text',
            "#{mainRoute?.elevationStats.gained} "
            @model.l.get 'abbr.imperial.foot'
          z '.icon',
            z @$mainLostIcon,
              icon: 'arrow-down'
              isTouchTarget: false
              color: colors.$secondary500
          z '.text',
            "#{mainRoute?.elevationStats.lost} "
            @model.l.get 'abbr.imperial.foot'

        if altRoute
          z '.alt',
            z '.icon',
              z @$altGainIcon,
                icon: 'arrow-up'
                isTouchTarget: false
                color: colors.$black54
            z '.text',
              "#{altRoute?.elevationStats.gained} "
              @model.l.get 'abbr.imperial.foot'
            z '.icon',
              z @$altLostIcon,
                icon: 'arrow-down'
                isTouchTarget: false
                color: colors.$black54
            z '.text',
              "#{altRoute?.elevationStats.lost} "
              @model.l.get 'abbr.imperial.foot'

      @$elevationChart
